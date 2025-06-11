const { ethers } = require('hardhat');

async function deployHTS(wallet) {
    const factory = await ethers.getContractFactory('HTS', wallet);
    const hts = await factory.deploy().then((d) => d.deployed());

    return hts.address;
}

async function deployWithHTSLibrary(wallet, contractName, htsAddress, args = []) {
    const factory = await ethers.getContractFactory(contractName, {
        signer: wallet,
        libraries: {
            HTS: htsAddress,
        },
    });
    const contract = await factory.deploy(...args).then((d) => d.deployed());

    return contract;
}

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log('Deploying HTS library with account:', deployer.address);
    console.log('Account balance:', (await deployer.getBalance()).toString());

    const htsAddress = await deployHTS(deployer);

    console.log('HTS deployment completed!');
    console.log('HTS library address:', htsAddress);

    return {
        hts: htsAddress,
    };
}

// Allow script to be run directly
if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = {
    deployHTS,
    deployWithHTSLibrary,
    main,
};
