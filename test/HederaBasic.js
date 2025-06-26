'use strict';

const chai = require('chai');
const { expect } = chai;
const { ethers } = require('hardhat');
const {
    Wallet,
    constants: { MaxUint256, AddressZero, HashZero },
    utils: { defaultAbiCoder, solidityPack, keccak256, toUtf8Bytes, hexlify, id, randomBytes },
    getContractAt,
} = ethers;

const { getCreate3Address } = require('@axelar-network/axelar-gmp-sdk-solidity');
const { approveContractCall } = require('../scripts/utils');
const {
    getRandomBytes32,
    getRandomInt,
    expectRevert,
    gasReporter,
    getEVMVersion,
    encodeInterchainTransferMessage,
    encodeDeployInterchainTokenMessage,
    encodeDeployTokenManagerMessage,
    encodeSendHubMessage,
    encodeReceiveHubMessage,
    encodeLinkTokenMessage,
    encodeRegisterTokenMetadataMessage,
    expectNonZeroAddress,
} = require('./utils');
const { deployAll, deployContract, deployInterchainTokenService } = require('../scripts/deploy');
const {
    MESSAGE_TYPE_INTERCHAIN_TRANSFER,
    MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER,
    INVALID_MESSAGE_TYPE,
    NATIVE_INTERCHAIN_TOKEN,
    MINT_BURN_FROM,
    LOCK_UNLOCK,
    LOCK_UNLOCK_FEE_ON_TRANSFER,
    MINT_BURN,
    OPERATOR_ROLE,
    FLOW_LIMITER_ROLE,
    ITS_HUB_CHAIN,
    ITS_HUB_ADDRESS,
    MINTER_ROLE,
    MESSAGE_TYPE_SEND_TO_HUB,
    INTERCHAIN_TRANSFER,
    INTERCHAIN_TRANSFER_WITH_METADATA_AND_GAS_VALUE,
} = require('./constants');
const { deployWHBAR, fundWithWHBAR } = require('../scripts/deploy-whbar');

describe.only('HederaBasic', () => {
    let wallet, otherWallet;
    let service, gateway, gasService, whbar;

    let create3Deployer;
    let tokenManagerDeployer;
    let interchainTokenDeployer;
    let tokenManager;
    let tokenHandler;

    const chainName = 'Test';

    const destinationChain = 'destination chain';
    const sourceChain = 'source chain';

    before(async () => {
        const wallets = await ethers.getSigners();
        wallet = wallets[0];
        otherWallet = wallets[1];

        ({
            service,
            gateway,
            gasService,
            create3Deployer,
            tokenManagerDeployer,
            interchainTokenDeployer,
            tokenManager,
            tokenHandler,
            whbar,
        } = await deployAll(wallet, 'Test', ITS_HUB_ADDRESS, [sourceChain, destinationChain]));
    });

    it('should deploy InterchainTokenService', async () => {
        const chainNameHash = await service.chainNameHash();
        console.log('Chain Name Hash:', chainNameHash);
        expect(chainNameHash).to.equal(keccak256(chainName));
    });

    it('should be funded with WHBAR', async () => {
        const balance = await whbar.balanceOf(service.address);
        expect(balance).to.be.gt(0, 'Service should have a non-zero WHBAR balance');
    });
});
