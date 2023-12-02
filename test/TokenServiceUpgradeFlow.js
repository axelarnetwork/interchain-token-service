'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const {
    utils: { keccak256, Interface, defaultAbiCoder },
    getContractAt,
} = ethers;
const { getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { approveContractCall } = require('../scripts/utils');
const { isHardhat, waitFor, getRandomBytes32, getPayloadAndProposalHash } = require('./utils');
const { deployContract, deployMockGateway, deployGasService, deployInterchainTokenService } = require('../scripts/deploy');
const { getBytecodeHash } = require('@axelar-network/axelar-chains-config');
const AxelarServiceGovernance = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/governance/AxelarServiceGovernance.sol/AxelarServiceGovernance.json');
const Create3Deployer = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/deploy/Create3Deployer.sol/Create3Deployer.json');

describe('Interchain Token Service Upgrade Flow', () => {
    let wallet, otherWallet, signer1, signer2, signer3;
    let service, gateway, gasService;
    let tokenManagerDeployer, interchainTokenDeployer, tokenManager, tokenHandler;
    let interchainTokenFactoryAddress;

    let axelarServiceGovernanceFactory;
    let axelarServiceGovernance;

    let governanceAddress;
    let buffer;

    const governanceChain = 'Governance Chain';
    const threshold = 2;
    const deploymentKey = 'InterchainTokenService';
    const chainName = 'Test';

    const tokenName = 'Token Name';
    const tokenSymbol = 'TN';
    const tokenDecimals = 13;

    async function testDeployTokenManager() {
        const salt = getRandomBytes32();
        const tokenId = await service.interchainTokenId(wallet.address, salt);
        const tokenManager = await getContractAt('TokenManager', await service.tokenManagerAddress(tokenId), wallet);

        const token = await deployContract(wallet, 'TestBaseInterchainToken', [
            tokenName,
            tokenSymbol,
            tokenDecimals,
            service.address,
            tokenId,
        ]);
        const params = defaultAbiCoder.encode(['bytes', 'address'], [wallet.address, token.address]);

        await expect(service.deployTokenManager(salt, '', 0, params, 0))
            .to.emit(service, 'TokenManagerDeployed')
            .withArgs(tokenId, tokenManager.address, 0, params);
    }

    before(async () => {
        [wallet, otherWallet, signer1, signer2, signer3] = await ethers.getSigners();
        const signers = [signer1, signer2, signer3];
        governanceAddress = otherWallet.address;

        buffer = isHardhat ? 10 * 60 * 60 : 10;

        const create3DeployerFactory = await ethers.getContractFactory(Create3Deployer.abi, Create3Deployer.bytecode, wallet);
        const create3Deployer = await create3DeployerFactory.deploy().then((d) => d.deployed());
        const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
        const interchainToken = await deployContract(wallet, 'InterchainToken', [interchainTokenServiceAddress]);

        gateway = await deployMockGateway(wallet);
        gasService = await deployGasService(wallet);
        tokenManagerDeployer = await deployContract(wallet, 'TokenManagerDeployer', []);
        interchainTokenDeployer = await deployContract(wallet, 'InterchainTokenDeployer', [interchainToken.address]);
        tokenManager = await deployContract(wallet, 'TokenManager', [interchainTokenServiceAddress]);
        tokenHandler = await deployContract(wallet, 'TokenHandler', []);
        interchainTokenFactoryAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey + 'Factory');

        axelarServiceGovernanceFactory = await ethers.getContractFactory(
            AxelarServiceGovernance.abi,
            AxelarServiceGovernance.bytecode,
            wallet,
        );

        axelarServiceGovernance = await axelarServiceGovernanceFactory
            .deploy(
                gateway.address,
                governanceChain,
                governanceAddress,
                buffer,
                signers.map((signer) => signer.address),
                threshold,
            )
            .then((d) => d.deployed());

        service = await deployInterchainTokenService(
            wallet,
            create3Deployer.address,
            tokenManagerDeployer.address,
            interchainTokenDeployer.address,
            gateway.address,
            gasService.address,
            interchainTokenFactoryAddress,
            tokenManager.address,
            tokenHandler.address,
            chainName,
            [],
            deploymentKey,
            axelarServiceGovernance.address,
        );
    });

    it('should upgrade Interchain Token Service through AxelarServiceGovernance timeLock proposal', async () => {
        const commandID = 0;
        const target = service.address;
        const nativeValue = 0;
        const timeDelay = isHardhat ? 12 * 60 * 60 : 12;

        const targetInterface = new Interface(service.interface.fragments);
        const newServiceImplementation = await deployContract(wallet, 'InterchainTokenService', [
            tokenManagerDeployer.address,
            interchainTokenDeployer.address,
            gateway.address,
            gasService.address,
            interchainTokenFactoryAddress,
            chainName,
            tokenManager.address,
            tokenHandler.address,
        ]);
        const newServiceImplementationCodeHash = await getBytecodeHash(newServiceImplementation);
        const setupParams = '0x';
        const calldata = targetInterface.encodeFunctionData('upgrade', [
            newServiceImplementation.address,
            newServiceImplementationCodeHash,
            setupParams,
        ]);

        const [payload, proposalHash, eta] = await getPayloadAndProposalHash(commandID, target, nativeValue, calldata, timeDelay);

        const commandIdGateway = getRandomBytes32();
        const sourceTxHash = keccak256('0x123abc123abc');
        const sourceEventIndex = 17;

        await approveContractCall(
            gateway,
            governanceChain,
            governanceAddress,
            axelarServiceGovernance.address,
            payload,
            sourceTxHash,
            sourceEventIndex,
            commandIdGateway,
        );

        const txExecute = await axelarServiceGovernance.execute(commandIdGateway, governanceChain, governanceAddress, payload);

        const receiptExecute = await txExecute.wait();
        const minimumEta = (await ethers.provider.getBlock(receiptExecute.blockNumber)).timestamp + buffer;
        const finalEta = minimumEta > eta ? minimumEta : eta;

        await expect(txExecute)
            .to.emit(axelarServiceGovernance, 'ProposalScheduled')
            .withArgs(proposalHash, target, calldata, nativeValue, finalEta);

        await waitFor(timeDelay);

        const tx = await axelarServiceGovernance.executeProposal(target, calldata, nativeValue);
        const receipt = await tx.wait();
        const executionTimestamp = (await ethers.provider.getBlock(receipt.blockNumber)).timestamp;

        await expect(tx)
            .to.emit(axelarServiceGovernance, 'ProposalExecuted')
            .withArgs(proposalHash, target, calldata, nativeValue, executionTimestamp)
            .and.to.emit(service, 'Upgraded')
            .withArgs(newServiceImplementation.address);

        await testDeployTokenManager();
    });

    it('should upgrade Interchain Token Service through AxelarServiceGovernance multisig proposal', async () => {
        const commandID = 2;
        const target = service.address;
        const nativeValue = 0;

        const targetInterface = new Interface(service.interface.fragments);
        const newServiceImplementation = await deployContract(wallet, 'InterchainTokenService', [
            tokenManagerDeployer.address,
            interchainTokenDeployer.address,
            gateway.address,
            gasService.address,
            interchainTokenFactoryAddress,
            chainName,
            tokenManager.address,
            tokenHandler.address,
        ]);
        const newServiceImplementationCodeHash = await getBytecodeHash(newServiceImplementation);
        const setupParams = '0x';
        const calldata = targetInterface.encodeFunctionData('upgrade', [
            newServiceImplementation.address,
            newServiceImplementationCodeHash,
            setupParams,
        ]);

        const [payload, proposalHash] = await getPayloadAndProposalHash(commandID, target, nativeValue, calldata);

        const commandIdGateway = getRandomBytes32();
        const sourceTxHash = keccak256('0x123abc123abc');
        const sourceEventIndex = 17;

        await approveContractCall(
            gateway,
            governanceChain,
            governanceAddress,
            axelarServiceGovernance.address,
            payload,
            sourceTxHash,
            sourceEventIndex,
            commandIdGateway,
        );

        await expect(axelarServiceGovernance.execute(commandIdGateway, governanceChain, governanceAddress, payload))
            .to.emit(axelarServiceGovernance, 'MultisigApproved')
            .withArgs(proposalHash, target, calldata, nativeValue);

        await axelarServiceGovernance
            .connect(signer1)
            .executeMultisigProposal(target, calldata, nativeValue)
            .then((tx) => tx.wait());

        await expect(axelarServiceGovernance.connect(signer2).executeMultisigProposal(target, calldata, nativeValue))
            .to.emit(axelarServiceGovernance, 'MultisigExecuted')
            .withArgs(proposalHash, target, calldata, nativeValue)
            .and.to.emit(service, 'Upgraded')
            .withArgs(newServiceImplementation.address);

        await testDeployTokenManager();
    });
});
