const { ethers } = require('hardhat');

async function deployWHBAR(wallet) {
    const factory = await ethers.getContractFactory('WHBAR', wallet);
    const whbar = await factory.deploy().then((d) => d.deployed());

    console.log(`Deployed WHBAR to ${whbar.address}`);
    return whbar;
}

async function fundWithWHBAR(whbar, targetAddress, amount, wallet) {
    console.log(`Funding ${targetAddress} with ${ethers.utils.formatUnits(amount, 18)} HBAR worth of WHBAR...`);

    // Deposit HBAR to get WHBAR
    const depositTx = await whbar.connect(wallet).deposit({ value: amount });
    await depositTx.wait();

    // Transfer WHBAR if target is different from wallet
    if (targetAddress.toLowerCase() !== wallet.address.toLowerCase()) {
        // See https://docs.hedera.com/hedera/core-concepts/smart-contracts/wrapped-hbar-whbar
        // as to why we need to scale down the amount
        const scale = 10 ** 10;
        const transferTx = await whbar.connect(wallet).transfer(targetAddress, amount / scale);
        await transferTx.wait();
    }

    const balance = await whbar.balanceOf(targetAddress);
    console.log(`${targetAddress} WHBAR balance: ${ethers.utils.formatUnits(balance, 8)} WHBAR`);
}

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log('Deploying WHBAR with account:', deployer.address);
    console.log('Account balance:', ethers.utils.formatEther(await deployer.getBalance()), 'HBAR');

    const whbar = await deployWHBAR(deployer);

    // Fund target address if provided via command line
    const targetAddress = process.argv[2];
    const fundingAmount = process.argv[3] ? ethers.utils.parseEther(process.argv[3]) : ethers.utils.parseEther('10');

    if (targetAddress) {
        await fundWithWHBAR(whbar, targetAddress, fundingAmount, deployer);
    }

    console.log('WHBAR deployment completed!');
    return whbar;
}

if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = {
    deployWHBAR,
    fundWithWHBAR,
    main,
};
