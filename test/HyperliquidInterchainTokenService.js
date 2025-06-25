const { expect } = require('chai');
const { ethers } = require('hardhat');
const { deployContract } = require('../scripts/deploy');

describe('HyperliquidInterchainTokenService', () => {
    let owner, user, otherUser;
    let hyperliquidService, hyperliquidToken1, hyperliquidToken2;
    let tokenManagerDeployer, interchainTokenDeployer, gateway, gasService;
    let create3Deployer, chainName, ITS_HUB_ADDRESS, tokenManager, tokenHandler;

    beforeEach(async () => {
        [owner, user, otherUser] = await ethers.getSigners();

        tokenManagerDeployer = await deployContract(owner, 'TokenManagerDeployer');

        const MockInterchainToken = await ethers.getContractFactory('TestInterchainTokenStandard', owner);
        const mockTokenImplementation = await MockInterchainToken.deploy(
            'Mock',
            'MOCK',
            18,
            ethers.constants.AddressZero,
            ethers.constants.HashZero,
        );

        interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [mockTokenImplementation.address]);
        gateway = await deployContract(owner, 'MockGateway');
        gasService = await deployContract(owner, 'AxelarGasService', [owner.address]);
        create3Deployer = await deployContract(owner, 'CreateDeploy');
        chainName = 'ethereum';
        ITS_HUB_ADDRESS = 'axelar1' + '0'.repeat(58);

        tokenManager = await deployContract(owner, 'TokenManager', [owner.address]);
        tokenHandler = await deployContract(owner, 'TokenHandler');

        // ✅ SECURITY FIX: Deploy implementation and proxy manually
        const HyperliquidInterchainTokenService = await ethers.getContractFactory('HyperliquidInterchainTokenService', owner);
        const implementation = await HyperliquidInterchainTokenService.deploy(
            tokenManagerDeployer.address,
            interchainTokenDeployer.address,
            gateway.address,
            gasService.address,
            create3Deployer.address,
            chainName,
            ITS_HUB_ADDRESS,
            tokenManager.address,
            tokenHandler.address,
        );

        // Deploy proxy
        const InterchainProxy = await ethers.getContractFactory('InterchainProxy', owner);
        const setupParams = ethers.utils.defaultAbiCoder.encode(
            ['address', 'string', 'string[]', 'string[]'],
            [owner.address, chainName, [], []]
        );
        
        const proxy = await InterchainProxy.deploy(
            implementation.address,
            owner.address,
            setupParams
        );

        // Get service interface on proxy
        hyperliquidService = HyperliquidInterchainTokenService.attach(proxy.address);

        const HyperliquidInterchainToken = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
        hyperliquidToken1 = await HyperliquidInterchainToken.deploy(hyperliquidService.address);
        hyperliquidToken2 = await HyperliquidInterchainToken.deploy(hyperliquidService.address);
    });

    describe('updateTokenDeployer', () => {
        it('should update deployer for a single token', async () => {
            expect(hyperliquidService.address).to.not.equal(ethers.constants.AddressZero);
            expect(hyperliquidToken1.address).to.not.equal(ethers.constants.AddressZero);
            expect(hyperliquidToken2.address).to.not.equal(ethers.constants.AddressZero);

            const newDeployer = user.address;

            await expect(hyperliquidService.updateTokenDeployer(hyperliquidToken1.address, newDeployer)).to.not.be.reverted;

            expect(await hyperliquidToken1.getDeployer()).to.equal(newDeployer);
        });

        it('should revert when called by non-operator', async () => {
            const newDeployer = user.address;

            await expect(
                hyperliquidService.connect(otherUser).updateTokenDeployer(hyperliquidToken1.address, newDeployer),
            ).to.be.revertedWithCustomError(hyperliquidService, 'NotOperatorOrOwner');
        });

        it('should allow setting deployer to zero address', async () => {
            await expect(hyperliquidService.updateTokenDeployer(hyperliquidToken1.address, ethers.constants.AddressZero)).to.not.be
                .reverted;

            expect(await hyperliquidToken1.getDeployer()).to.equal(ethers.constants.AddressZero);
        });
    });
});
