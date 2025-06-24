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

        // Deploy dependencies
        tokenManagerDeployer = await deployContract(owner, 'TokenManagerDeployer');
        
        // Deploy a mock interchain token implementation first
        const MockInterchainToken = await ethers.getContractFactory('TestInterchainTokenStandard', owner);
        const mockTokenImplementation = await MockInterchainToken.deploy('Mock', 'MOCK', 18, ethers.constants.AddressZero, ethers.constants.HashZero);
        
        interchainTokenDeployer = await deployContract(owner, 'InterchainTokenDeployer', [mockTokenImplementation.address]);
        gateway = await deployContract(owner, 'MockGateway');
        gasService = await deployContract(owner, 'AxelarGasService', [owner.address]);
        create3Deployer = await deployContract(owner, 'CreateDeploy'); // Use local CreateDeploy contract
        chainName = 'ethereum';
        ITS_HUB_ADDRESS = 'axelar1' + '0'.repeat(58); // Valid 65-character string
        
        // Deploy TokenManager and TokenHandler first
        tokenManager = await deployContract(owner, 'TokenManager', [owner.address]); // Use owner.address as placeholder if needed
        tokenHandler = await deployContract(owner, 'TokenHandler');

        // Deploy HyperliquidInterchainTokenService with real addresses
        const HyperliquidInterchainTokenService = await ethers.getContractFactory('HyperliquidInterchainTokenService', owner);
        hyperliquidService = await HyperliquidInterchainTokenService.deploy(
            tokenManagerDeployer.address,
            interchainTokenDeployer.address,
            gateway.address,
            gasService.address,
            create3Deployer.address, // factory address
            chainName,
            ITS_HUB_ADDRESS,
            tokenManager.address,
            tokenHandler.address
        );

        // Deploy test tokens
        const HyperliquidInterchainToken = await ethers.getContractFactory('HyperliquidInterchainToken', owner);
        hyperliquidToken1 = await HyperliquidInterchainToken.deploy(hyperliquidService.address);
        hyperliquidToken2 = await HyperliquidInterchainToken.deploy(hyperliquidService.address);
    });

    describe('updateTokenDeployer', () => {
        it('should update deployer for a single token', async () => {
            // Verify the service and tokens are deployed correctly
            expect(hyperliquidService.address).to.not.equal(ethers.constants.AddressZero);
            expect(hyperliquidToken1.address).to.not.equal(ethers.constants.AddressZero);
            expect(hyperliquidToken2.address).to.not.equal(ethers.constants.AddressZero);
            
            // The service should be able to update the deployer
            const newDeployer = user.address;
            
            await expect(
                hyperliquidService.updateTokenDeployer(hyperliquidToken1.address, newDeployer)
            ).to.not.be.reverted;
            
            // Verify the deployer was updated
            expect(await hyperliquidToken1.getDeployer()).to.equal(newDeployer);
        });

        it('should revert when called by non-operator', async () => {
            const newDeployer = user.address;
            
            await expect(
                hyperliquidService.connect(otherUser).updateTokenDeployer(hyperliquidToken1.address, newDeployer)
            ).to.be.revertedWithCustomError(hyperliquidService, 'NotOperatorOrOwner');
        });

        it('should allow setting deployer to zero address', async () => {
            // The service should be able to set deployer to zero address
            await expect(
                hyperliquidService.updateTokenDeployer(hyperliquidToken1.address, ethers.constants.AddressZero)
            ).to.not.be.reverted;
            
            // Verify the deployer was set to zero
            expect(await hyperliquidToken1.getDeployer()).to.equal(ethers.constants.AddressZero);
        });
    });
}); 