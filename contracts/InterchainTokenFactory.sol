// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressBytes } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/AddressBytes.sol';
import { Multicall } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/utils/Multicall.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';
import { IInterchainTokenService } from './interfaces/IInterchainTokenService.sol';
import { IInterchainTokenFactory } from './interfaces/IInterchainTokenFactory.sol';
import { ITokenManager } from './interfaces/ITokenManager.sol';
import { IInterchainToken } from './interfaces/IInterchainToken.sol';
import { IERC20Named } from './interfaces/IERC20Named.sol';

/**
 * @title InterchainTokenFactory
 * @notice This contract is responsible for deploying new interchain tokens and managing their token managers.
 */
contract InterchainTokenFactory is IInterchainTokenFactory, Multicall, Upgradable {
    using AddressBytes for address;

    /// @dev This slot contains the storage for this contract in an upgrade-compatible manner
    /// keccak256('InterchainTokenFactory.Slot') - 1;
    bytes32 internal constant INTERCHAIN_TOKEN_FACTORY_SLOT = 0xd4f5c43117c663161acfe6af3208a49856d85e586baf0f60749de2055e001465;

    bytes32 private constant CONTRACT_ID = keccak256('interchain-token-factory');
    bytes32 internal constant PREFIX_CANONICAL_TOKEN_SALT = keccak256('canonical-token-salt');
    bytes32 internal constant PREFIX_INTERCHAIN_TOKEN_SALT = keccak256('interchain-token-salt');
    bytes32 internal constant PREFIX_DEPLOY_APPROVAL = keccak256('deploy-approval');
    bytes32 internal constant PREFIX_CUSTOM_TOKEN_SALT = keccak256('custom-token-salt');
    address private constant TOKEN_FACTORY_DEPLOYER = address(0);

    IInterchainTokenService public immutable interchainTokenService;
    bytes32 public immutable chainNameHash;

    struct DeployApproval {
        address minter;
        bytes32 tokenId;
        string destinationChain;
    }

    /// @dev Storage for this contract
    /// @param approvedDestinationMinters Mapping of approved destination minters
    struct InterchainTokenFactoryStorage {
        mapping(bytes32 => bytes32) approvedDestinationMinters;
    }

    /**
     * @notice Constructs the InterchainTokenFactory contract.
     * @param interchainTokenService_ The address of the interchain token service.
     */
    constructor(address interchainTokenService_) {
        if (interchainTokenService_ == address(0)) revert ZeroAddress();

        interchainTokenService = IInterchainTokenService(interchainTokenService_);

        chainNameHash = interchainTokenService.chainNameHash();
    }

    function _setup(bytes calldata /* data */) internal pure override {}

    /**
     * @notice Getter for the contract id.
     * @return bytes32 The contract id of this contract.
     */
    function contractId() external pure returns (bytes32) {
        return CONTRACT_ID;
    }

    /**
     * @notice Computes the deploy salt for an interchain token.
     * @param deployer The address of the deployer.
     * @param salt A unique identifier to generate the salt.
     * @return deploySalt The deploy salt for the interchain token.
     */
    function interchainTokenDeploySalt(address deployer, bytes32 salt) public view returns (bytes32 deploySalt) {
        deploySalt = keccak256(abi.encode(PREFIX_INTERCHAIN_TOKEN_SALT, chainNameHash, deployer, salt));
    }

    /**
     * @notice Computes the deploy salt for a canonical interchain token.
     * @param tokenAddress The address of the token.
     * @return deploySalt The deploy salt for the interchain token.
     */
    function canonicalInterchainTokenDeploySalt(address tokenAddress) public view returns (bytes32 deploySalt) {
        deploySalt = keccak256(abi.encode(PREFIX_CANONICAL_TOKEN_SALT, chainNameHash, tokenAddress));
    }

    /**
     * @notice Computes the ID for an interchain token based on the deployer and a salt.
     * @param deployer The address that deployed the interchain token.
     * @param salt A unique identifier used in the deployment process.
     * @return tokenId The ID of the interchain token.
     */
    function interchainTokenId(address deployer, bytes32 salt) public view returns (bytes32 tokenId) {
        bytes32 deploySalt = interchainTokenDeploySalt(deployer, salt);
        tokenId = _interchainTokenId(deploySalt);
    }

    /**
     * @notice Computes the ID for a canonical interchain token based on its address.
     * @param tokenAddress The address of the canonical interchain token.
     * @return tokenId The ID of the canonical interchain token.
     */
    function canonicalInterchainTokenId(address tokenAddress) public view returns (bytes32 tokenId) {
        bytes32 deploySalt = canonicalInterchainTokenDeploySalt(tokenAddress);
        tokenId = _interchainTokenId(deploySalt);
    }

    /**
     * @notice Computes the tokenId for an interchain token based on the deploySalt.
     * @param deploySalt The salt used for the deployment.
     * @return tokenId The tokenId of the interchain token.
     */
    function _interchainTokenId(bytes32 deploySalt) internal view returns (bytes32 tokenId) {
        tokenId = interchainTokenService.interchainTokenId(TOKEN_FACTORY_DEPLOYER, deploySalt);
    }

    /**
     * @notice Deploys a new interchain token with specified parameters.
     * @dev Creates a new token and optionally mints an initial amount to a specified minter.
     * This function is `payable` because non-payable functions cannot be called in a multicall that calls other `payable` functions.
     * Cannot deploy tokens with empty supply and no minter.
     * @param salt The unique salt for deploying the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals for the token.
     * @param initialSupply The amount of tokens to mint initially (can be zero), allocated to the msg.sender.
     * @param minter The address to receive the minter and operator role of the token, in addition to ITS. If it is set to `address(0)`,
     * the additional minter isn't set, and can't be added later. This allows creating tokens that are managed only by ITS, reducing trust assumptions.
     * Reverts if the minter is the ITS address since it's already added as a minter.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployInterchainToken(
        bytes32 salt,
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 initialSupply,
        address minter
    ) external payable returns (bytes32 tokenId) {
        address sender = msg.sender;
        bytes32 deploySalt = interchainTokenDeploySalt(sender, salt);
        bytes memory minterBytes = new bytes(0);
        string memory currentChain = '';
        uint256 gasValue = 0;

        if (initialSupply > 0) {
            minterBytes = address(this).toBytes();
        } else if (minter != address(0)) {
            if (minter == address(interchainTokenService)) revert InvalidMinter(minter);

            minterBytes = minter.toBytes();
        } else {
            revert ZeroSupplyToken();
        }

        tokenId = _deployInterchainToken(deploySalt, currentChain, name, symbol, decimals, minterBytes, gasValue);

        if (initialSupply > 0) {
            IInterchainToken token = IInterchainToken(interchainTokenService.registeredTokenAddress(tokenId));
            ITokenManager tokenManager = ITokenManager(interchainTokenService.deployedTokenManager(tokenId));

            token.mint(sender, initialSupply);

            token.transferMintership(minter);
            tokenManager.removeFlowLimiter(address(this));

            // If minter == address(0), we still set it as a flow limiter for consistency with the remote token manager.
            tokenManager.addFlowLimiter(minter);

            tokenManager.transferOperatorship(minter);
        }
    }

    /**
     * @notice Allow the minter to approve the deployer for a remote interchain token deployment that uses a custom destinationMinter address.
     * This ensures that a token deployer can't choose the destinationMinter itself, and requires the approval of the minter to reduce trust assumptions on the deployer.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     * @param destinationMinter The minter address to set on the deployed token on the destination chain. This can be arbitrary bytes
     * since the encoding of the account is dependent on the destination chain.
     */
    function approveDeployRemoteInterchainToken(
        address deployer,
        bytes32 salt,
        string calldata destinationChain,
        bytes calldata destinationMinter
    ) external {
        address minter = msg.sender;
        bytes32 tokenId = interchainTokenId(deployer, salt);

        _checkTokenMinter(tokenId, minter);

        if (!interchainTokenService.isTrustedChain(destinationChain)) revert InvalidChainName();

        bytes32 approvalKey = _deployApprovalKey(DeployApproval({ minter: minter, tokenId: tokenId, destinationChain: destinationChain }));

        _interchainTokenFactoryStorage().approvedDestinationMinters[approvalKey] = keccak256(destinationMinter);

        emit DeployRemoteInterchainTokenApproval(minter, deployer, tokenId, destinationChain, destinationMinter);
    }

    /**
     * @notice Allows the minter to revoke a deployer's approval for a remote interchain token deployment that uses a custom destinationMinter address.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     */
    function revokeDeployRemoteInterchainToken(address deployer, bytes32 salt, string calldata destinationChain) external {
        address minter = msg.sender;
        bytes32 tokenId = interchainTokenId(deployer, salt);

        bytes32 approvalKey = _deployApprovalKey(DeployApproval({ minter: minter, tokenId: tokenId, destinationChain: destinationChain }));

        delete _interchainTokenFactoryStorage().approvedDestinationMinters[approvalKey];

        emit RevokedDeployRemoteInterchainTokenApproval(minter, deployer, tokenId, destinationChain);
    }

    /**
     * @dev Compute the key for the deploy approval mapping.
     */
    function _deployApprovalKey(DeployApproval memory approval) internal pure returns (bytes32 key) {
        key = keccak256(abi.encode(PREFIX_DEPLOY_APPROVAL, approval));
    }

    /**
     * @dev Use the deploy approval to check that the destination minter is valid and then delete the approval.
     */
    function _useDeployApproval(DeployApproval memory approval, bytes memory destinationMinter) internal {
        bytes32 approvalKey = _deployApprovalKey(approval);

        InterchainTokenFactoryStorage storage slot = _interchainTokenFactoryStorage();

        if (slot.approvedDestinationMinters[approvalKey] != keccak256(destinationMinter)) revert RemoteDeploymentNotApproved();

        delete slot.approvedDestinationMinters[approvalKey];
    }

    /**
     * @notice Deploys a remote interchain token on a specified destination chain. No additional minter is set on the deployed token.
     * Use the `deployRemoteInterchainTokenWithMinter` method to do so.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     * @param gasValue The amount of gas to send for the deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployRemoteInterchainToken(
        bytes32 salt,
        string calldata destinationChain,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId) {
        bytes32 deploySalt = interchainTokenDeploySalt(msg.sender, salt);

        tokenId = _deployRemoteInterchainToken(deploySalt, destinationChain, new bytes(0), gasValue);
    }

    /**
     * @notice Deploys a remote interchain token on a specified destination chain.
     * @param salt The unique salt for deploying the token.
     * @param minter The minter of the interchain token on the current chain. If the token has no minter other than ITS, then no minter can be set on the interchain token on the destination chain, and `deployRemoteInterchainToken` must be used instead.
     * @param destinationChain The name of the destination chain.
     * @param destinationMinter The address to receive the minter and operator role of the token on the destination chain. This can be arbitrary bytes
     * since the encoding of the account is dependent on the destination chain. The `minter` must have approved a custom `destinationMinter` via `approveDeployRemoteInterchainToken` beforehand. If this is empty, then the `minter` of the token on the current chain
     * is used as the destination minter, which makes it convenient when deploying to other EVM chains.
     * @param gasValue The amount of gas to send for the deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployRemoteInterchainTokenWithMinter(
        bytes32 salt,
        address minter,
        string calldata destinationChain,
        bytes memory destinationMinter,
        uint256 gasValue
    ) public payable returns (bytes32 tokenId) {
        if (minter == address(0)) {
            revert InvalidMinter(minter);
        }

        bytes32 deploySalt = interchainTokenDeploySalt(msg.sender, salt);
        bytes32 deployedTokenId = _interchainTokenId(deploySalt);

        _checkTokenMinter(deployedTokenId, minter);

        if (destinationMinter.length > 0) {
            DeployApproval memory approval = DeployApproval({
                minter: minter,
                tokenId: deployedTokenId,
                destinationChain: destinationChain
            });
            _useDeployApproval(approval, destinationMinter);
        } else {
            destinationMinter = minter.toBytes();
        }

        tokenId = _deployRemoteInterchainToken(deploySalt, destinationChain, destinationMinter, gasValue);
    }

    /**
     * @notice Checks that the minter is registered for the token on the current chain and not the token manager of the token.
     * @param tokenId The unique identifier for the token. The token must be an interchain token deployed via ITS.
     * @param minter The address to be checked as a minter for the interchain token.
     */
    function _checkTokenMinter(bytes32 tokenId, address minter) internal view {
        // Ensure that the minter is registered for the token on the current chain
        IInterchainToken token = IInterchainToken(interchainTokenService.registeredTokenAddress(tokenId));
        if (!token.isMinter(minter)) revert NotMinter(minter);

        // Sanity check to prevent accidental use of the token manager of the token on the current chain as the token minter
        address tokenManager = address(interchainTokenService.deployedTokenManager(tokenId));
        if (minter == tokenManager) revert InvalidMinter(minter);
    }

    /**
     * @notice Deploys a new interchain token with specified parameters.
     * @param salt The unique salt for deploying the token.
     * @param destinationChain The name of the destination chain.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbol of the token.
     * @param tokenDecimals The number of decimals for the token.
     * @param minter The address to receive the initially minted tokens.
     * @param gasValue The amount of gas to send for the transfer.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function _deployInterchainToken(
        bytes32 salt,
        string memory destinationChain,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        bytes memory minter,
        uint256 gasValue
    ) internal returns (bytes32 tokenId) {
        // slither-disable-next-line arbitrary-send-eth
        tokenId = interchainTokenService.deployInterchainToken{ value: gasValue }(
            salt,
            destinationChain,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            minter,
            gasValue
        );
    }

    /**
     * @notice Deploys a remote interchain token on a specified destination chain.
     * @param deploySalt The salt used for the deployment.
     * @param destinationChain The name of the destination chain.
     * @param minter The address to receive the minter and operator role of the token, in addition to ITS.
     * @param gasValue The amount of gas to send for the deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function _deployRemoteInterchainToken(
        bytes32 deploySalt,
        string calldata destinationChain,
        bytes memory minter,
        uint256 gasValue
    ) internal returns (bytes32 tokenId) {
        // Ensure that a token is registered locally for the tokenId before allowing a remote deployment
        bytes32 expectedTokenId = _interchainTokenId(deploySalt);
        address tokenAddress = interchainTokenService.registeredTokenAddress(expectedTokenId);

        // The local token must expose the name, symbol, and decimals metadata
        (string memory name, string memory symbol, uint8 decimals) = _getTokenMetadata(tokenAddress);

        tokenId = _deployInterchainToken(deploySalt, destinationChain, name, symbol, decimals, minter, gasValue);
        if (tokenId != expectedTokenId) revert InvalidTokenId(tokenId, expectedTokenId);
    }

    /**
     * @notice Registers a canonical token as an interchain token and deploys its token manager.
     * @dev This function is `payable` because non-payable functions cannot be called in a multicall that calls other `payable` functions.
     * @param tokenAddress The address of the canonical token.
     * @return tokenId The tokenId corresponding to the registered canonical token.
     */
    function registerCanonicalInterchainToken(address tokenAddress) external payable returns (bytes32 tokenId) {
        bytes32 deploySalt = canonicalInterchainTokenDeploySalt(tokenAddress);
        // No custom operator is set for canonical token registration
        bytes memory linkParams = '';

        // Ensure that the ERC20 token has metadata before registering it
        // slither-disable-next-line unused-return
        _getTokenMetadata(tokenAddress);

        tokenId = interchainTokenService.registerCustomToken(deploySalt, tokenAddress, TokenManagerType.LOCK_UNLOCK, linkParams);
    }

    /**
     * @notice Retrieves the metadata of an ERC20 token. Reverts with `NotToken` error if metadata is not available.
     * @param tokenAddress The address of the token.
     * @return name The name of the token.
     * @return symbol The symbol of the token.
     * @return decimals The number of decimals for the token.
     */
    function _getTokenMetadata(address tokenAddress) internal view returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20Named token = IERC20Named(tokenAddress);

        try token.name() returns (string memory name_) {
            name = name_;
        } catch {
            revert NotToken(tokenAddress);
        }

        try token.symbol() returns (string memory symbol_) {
            symbol = symbol_;
        } catch {
            revert NotToken(tokenAddress);
        }

        try token.decimals() returns (uint8 decimals_) {
            decimals = decimals_;
        } catch {
            revert NotToken(tokenAddress);
        }
    }

    /**
     * @notice Deploys a canonical interchain token on a remote chain.
     * @param originalTokenAddress The address of the original token on the original chain.
     * @param destinationChain The name of the chain where the token will be deployed.
     * @param gasValue The gas amount to be sent for deployment.
     * @return tokenId The tokenId corresponding to the deployed InterchainToken.
     */
    function deployRemoteCanonicalInterchainToken(
        address originalTokenAddress,
        string calldata destinationChain,
        uint256 gasValue
    ) public payable returns (bytes32 tokenId) {
        // No additional minter is set on a canonical token deployment
        bytes memory minter = '';
        bytes32 deploySalt = canonicalInterchainTokenDeploySalt(originalTokenAddress);

        tokenId = _deployRemoteInterchainToken(deploySalt, destinationChain, minter, gasValue);
    }

    /**
     * @notice Computes the deploy salt for a linked interchain token.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @return deploySalt The deploy salt for the interchain token.
     */
    function linkedTokenDeploySalt(address deployer, bytes32 salt) public view returns (bytes32 deploySalt) {
        deploySalt = keccak256(abi.encode(PREFIX_CUSTOM_TOKEN_SALT, chainNameHash, deployer, salt));
    }

    /**
     * @notice Computes the ID for a linked token based on its address.
     * @param deployer The address of the deployer.
     * @param salt The unique salt for deploying the token.
     * @return tokenId The ID of the linked token.
     */
    function linkedTokenId(address deployer, bytes32 salt) external view returns (bytes32 tokenId) {
        bytes32 deploySalt = linkedTokenDeploySalt(deployer, salt);
        tokenId = _interchainTokenId(deploySalt);
    }

    /**
     * @notice Register an existing ERC20 token under a `tokenId` computed from the provided `salt`.
     * A token metadata registration message will also be sent to the ITS Hub.
     * This token can then be linked to remote tokens on different chains by submitting the `linkToken` function from the same `msg.sender` and using the same `salt`.
     * @dev This function is marked as payable since it can be called within a multicall with other payable methods.
     * @param salt The salt used to derive the tokenId for the custom token registration. The same salt must be used when linking this token on other chains under the same tokenId.
     * @param tokenAddress The token address of the token being registered.
     * @param tokenManagerType The token manager type used for the token link.
     * @param operator The operator of the token manager.
     */
    function registerCustomToken(
        bytes32 salt,
        address tokenAddress,
        TokenManagerType tokenManagerType,
        address operator
    ) external payable returns (bytes32 tokenId) {
        bytes32 deploySalt = linkedTokenDeploySalt(msg.sender, salt);
        bytes memory linkParams = '';
        if (operator != address(0)) {
            linkParams = operator.toBytes();
        }

        tokenId = interchainTokenService.registerCustomToken(deploySalt, tokenAddress, tokenManagerType, linkParams);
    }

    /**
     * @notice Links a remote token on `destinationChain` to a local token corresponding to the `tokenId` computed from the provided `salt`.
     * A local token must have been registered first using the `registerCustomToken` function.
     * @param salt The salt used to derive the tokenId for the custom token registration. The same salt must be used when linking this token on other chains under the same tokenId.
     * @param destinationChain The name of the destination chain.
     * @param destinationTokenAddress The token address of the token being linked.
     * @param tokenManagerType The token manager type used for the token link.
     * @param linkParams Additional parameters for the token link depending on the destination chain. For EVM destination chains, this is an optional custom operator address.
     * @param gasValue The cross-chain gas value used to link the token on the destination chain.
     * @return tokenId The tokenId corresponding to the linked token.
     */
    function linkToken(
        bytes32 salt,
        string calldata destinationChain,
        bytes calldata destinationTokenAddress,
        TokenManagerType tokenManagerType,
        bytes calldata linkParams,
        uint256 gasValue
    ) external payable returns (bytes32 tokenId) {
        bytes32 deploySalt = linkedTokenDeploySalt(msg.sender, salt);
        tokenId = interchainTokenService.linkToken{ value: gasValue }(
            deploySalt,
            destinationChain,
            destinationTokenAddress,
            tokenManagerType,
            linkParams,
            gasValue
        );
    }

    /********************\
    |* Pure Key Getters *|
    \********************/

    /**
     * @notice Gets the specific storage location for preventing upgrade collisions
     * @return slot containing the storage struct
     */
    function _interchainTokenFactoryStorage() private pure returns (InterchainTokenFactoryStorage storage slot) {
        assembly {
            slot.slot := INTERCHAIN_TOKEN_FACTORY_SLOT
        }
    }
}
