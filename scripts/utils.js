const { Wallet, getDefaultProvider, Contract } = require("ethers");

const Token = require('../artifacts/contracts/interfaces/IERC20BurnableMintable.sol/IERC20BurnableMintable.json');
const ITokenService = require('../artifacts/contracts/interfaces/IInterchainTokenService.sol/IInterchainTokenService.json');
const ITokenDeployer = require('../artifacts/contracts/interfaces/ITokenDeployer.sol/ITokenDeployer.json');
const Test = require('../artifacts/contracts/test/TokenLinkerExecutableTest.sol/TokenLinkerExecutableTest.json');
const { IAxelarExecutable } = require('@axelar-network/axelar-local-dev/dist/contracts/index.js');
const { deployLinkerRouter, deployTokenDeployer, deployTokenService } = require("./deploy");
const { createNetwork, networks, deployContract, relay, evmRelayer } = require("@axelar-network/axelar-local-dev");

async function setupLocal(toFund, n) {
    for (let i = 0; i < n; i++) {
        const network = await createNetwork({ port: 8510 + i });
        const user = network.userWallets[0];

        for (const account of toFund) {
            await user
                .sendTransaction({
                    to: account,
                    value: BigInt(100e18),
                })
                .then((tx) => tx.wait());
        }
    }

    const chains = networks.map((network) => {
        const info = network.getCloneInfo();
        info.rpc = info.rpc = `http://localhost:${network.port}`;
        return info;
    });
    return chains;
}

async function prepareChain(chain, ownerKey, otherKey) {
    chain.provider = getDefaultProvider(chain.rpc);
    chain.ownerWallet = new Wallet(ownerKey, chain.provider);
    chain.otherWallet = new Wallet(otherKey, chain.provider);

    
    await deployLinkerRouter(chain, chain.ownerWallet);
    await deployTokenDeployer(chain, chain.ownerWallet);
    await deployTokenService(chain, chain.ownerWallet);
    chain.executable = await deployContract(chain.ownerWallet, Test);


    chain.service = new Contract(chain.interchainTokenService, ITokenService.abi, chain.ownerWallet);
    chain.deployer = new Contract(chain.tokenDeployer, ITokenDeployer.abi, chain.ownerWallet);
}

async function deployToken(chain, name, symbol, decimals, owner, salt, options = {}) {
    let tokenAddress, tokenId;
    remoteDeployments = options.remoteDeployments || []
    if(options.fromService) {
        await chain.service.deployInterchainToken(
            name,
            symbol,
            decimals,
            owner,
            salt,
            remoteDeployments,
            remoteDeployments.map(() => 1e7),
            {value: 1e7*remoteDeployments.length},
        );
        tokenAddress = await chain.service.getDeploymentAddress(chain.ownerWallet.address, salt);
        tokenId = await chain.service.getInterchainTokenId(chain.ownerWallet.address, salt);
    } else {
        await chain.deployer.deployToken(name, symbol, decimals, owner, salt);
        tokenAddress = await chain.deployer.getDeploymentAddress(chain.deployer.address, salt);
        tokenId = await chain.service.getOriginTokenId(tokenAddress);
        if(options.register) {
            if(options.remoteDeployments) {
                await chain.service.registerOriginTokenAndDeployRemoteTokens(
                    tokenAddress,
                    remoteDeployments,
                    remoteDeployments.map(() => 1e7),
                    {value: 1e7*remoteDeployments.length},
                )
            } else {
                await chain.service.registerToken(tokenAddress);
            }
        }
    }
    await relay();
    const token = new Contract(tokenAddress, Token.abi, chain.ownerWallet);
    return [token, tokenId];
}

async function relayRevert(tx, withToken = false, n = 1) {
    const receipt = await (await tx).wait();
    const transactionHash = receipt.transactionHash;
    await relay();
    const contractCalls = Object.values(evmRelayer.relayData[`callContract${withToken ? 'WithToken' : ''}`]);

    for (let i = 0; i < n; i++) {
        const command = contractCalls[contractCalls.length - 1 - i];
        if(command.transactionHash != transactionHash) return false;
        if(command.execution) return false;
    }
    return true;
}

async function getTokenData(chain, deployerAddress, salt, deployedAtService = false) {
    let tokenAddress, tokenId;

    if (deployedAtService) {
        tokenAddress = await chain.service.getDeploymentAddress(deployerAddress, salt);
        tokenId = await chain.service.getInterchainTokenId(deployerAddress, salt);
    } else {
        tokenAddress = await chain.deployer.getDeploymentAddress(chain.deployer.address, salt);
        tokenId = await chain.service.getOriginTokenId(tokenAddress);
    }

    return [tokenAddress, tokenId];
}

async function relayAndFulfill(remoteWallet) {
    const n1 = Object.values(evmRelayer.relayData.callContract).length;
    const m1 = Object.values(evmRelayer.relayData.callContractWithToken).length;
    await relay();
    const n2 = Object.values(evmRelayer.relayData.callContract).length;
    const m2 = Object.values(evmRelayer.relayData.callContractWithToken).length;

    let commands = evmRelayer.relayData.callContract;
    for(let i=n1; i<n2; i++) {
        const commandId = Object.keys(commands)[i];
        const command = commands[commandId];
        const payload = command.payload;
        
        const executable = new Contract(command.destinationContractAddress, IAxelarExecutable.abi, remoteWallet);
        await executable.execute(commandId, command.from, command.sourceAddress, payload);
    } 
    commands = evmRelayer.relayData.callContractWithToken;
    for(let i=m1; i<m2; i++) {
        const commandId = Object.keys(commands)[i];
        const command = commands[commandId];
        const payload = command.payload;

        const executable = new Contract(command.destinationContractAddress, IAxelarExecutable.abi, remoteWallet);

        await executable.executeWithToken(
            commandId,
            command.from,
            command.sourceAddress,
            payload,
            command.destinationTokenSymbol,
            command.amountOut,
        );
    }
}

module.exports = {
    setupLocal,
    prepareChain,
    deployToken,
    relayRevert,
    getTokenData,
    relayAndFulfill,
}