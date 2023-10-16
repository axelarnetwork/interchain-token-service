'use strict';

const chai = require('chai');
const { expect } = chai;
require('dotenv').config();
const { ethers } = require('hardhat');
const { keccak256, Interface } = ethers.utils;
const { getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { approveContractCall } = require('../scripts/utils');
const { isHardhat, waitFor, getRandomBytes32, getPayloadAndProposalHash } = require('./utils');
const {
    deployContract,
    deployMockGateway,
    deployGasService,
    deployInterchainTokenService,
    deployRemoteAddressValidator,
    deployTokenManagerImplementations,
} = require('../scripts/deploy');
const { getBytecodeHash } = require('@axelar-network/axelar-chains-config');
const AxelarServiceGovernance = require('@axelar-network/axelar-gmp-sdk-solidity/artifacts/contracts/governance/AxelarServiceGovernance.sol/AxelarServiceGovernance.json');

describe('Interchain Token Service Upgrade Flow', () => {
    let wallet, otherWallet, signer1, signer2, signer3;
    let service, gateway, gasService;
    let tokenManagerDeployer, standardizedTokenDeployer, remoteAddressValidator, tokenManagerImplementations;

    let axelarServiceGovernanceFactory;
    let axelarServiceGovernance;

    let governanceAddress;
    let buffer;

    const governanceChain = 'Governance Chain';
    const threshold = 2;
    const deploymentKey = 'InterchainTokenService';

    before(async () => {
        [wallet, otherWallet, signer1, signer2, signer3] = await ethers.getSigners();
        const signers = [signer1, signer2, signer3];
        governanceAddress = otherWallet.address;

        buffer = isHardhat ? 10 * 60 * 60 : 10;

        const create3Deployer = await deployContract(wallet, 'Create3Deployer');
        const interchainTokenServiceAddress = await getCreate3Address(create3Deployer.address, wallet, deploymentKey);
        const standardizedToken = await deployContract(wallet, 'StandardizedToken');

        gateway = await deployMockGateway(wallet);
        gasService = await deployGasService(wallet);
        tokenManagerDeployer = await deployContract(wallet, 'TokenManagerDeployer', []);
        standardizedTokenDeployer = await deployContract(wallet, 'StandardizedTokenDeployer', [standardizedToken.address]);
        remoteAddressValidator = await deployRemoteAddressValidator(wallet, 'Test', interchainTokenServiceAddress);
        tokenManagerImplementations = await deployTokenManagerImplementations(wallet, interchainTokenServiceAddress);

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
            standardizedTokenDeployer.address,
            gateway.address,
            gasService.address,
            remoteAddressValidator.address,
            tokenManagerImplementations.map((impl) => impl.address),
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
            standardizedTokenDeployer.address,
            gateway.address,
            gasService.address,
            remoteAddressValidator.address,
            tokenManagerImplementations.map((impl) => impl.address),
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
    });

    it('should upgrade Interchain Token Service through AxelarServiceGovernance multisig proposal', async () => {
        const commandID = 2;
        const target = service.address;
        const nativeValue = 0;

        const targetInterface = new Interface(service.interface.fragments);
        const newServiceImplementation = await deployContract(wallet, 'InterchainTokenService', [
            tokenManagerDeployer.address,
            standardizedTokenDeployer.address,
            gateway.address,
            gasService.address,
            remoteAddressValidator.address,
            tokenManagerImplementations.map((impl) => impl.address),
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
    });
});
