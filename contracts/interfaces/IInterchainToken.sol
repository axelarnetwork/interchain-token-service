// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenStandard } from './IInterchainTokenStandard.sol';
import { IDistributable } from './IDistributable.sol';
import { IERC20MintableBurnable } from './IERC20MintableBurnable.sol';
import { IERC20Named } from './IERC20Named.sol';

/**
 * @title IInterchainToken interface
 * @dev Extends IInterchainTokenStandard and IDistributable.
 */
interface IInterchainToken is IInterchainTokenStandard, IDistributable, IERC20MintableBurnable, IERC20Named {
    error InterchainTokenServiceAddressZero();
    error TokenIdZero();
    error TokenNameEmpty();
    error AlreadyInitialized();

    /**
     * @notice Getter for the interchain token service contract.
     * @dev Needs to be overwitten.
     * @return interchainTokenServiceAddress The interchain token service address.
     */
    function interchainTokenService() external view returns (address interchainTokenServiceAddress);

    /**
     * @notice Getter for the tokenId used for this token.
     * @dev Needs to be overwitten.
     * @return tokenId_ The tokenId for this token.
     */
    function interchainTokenId() external view returns (bytes32 tokenId_);

    /**
     * @notice Setup function to initialize contract parameters.
     * @param tokenId_ The tokenId of the token.
     * @param minter The address of the token minter.
     * @param tokenName The name of the token.
     * @param tokenSymbol The symbopl of the token.
     * @param tokenDecimals The decimals of the token.
     */
    function init(bytes32 tokenId_, address minter, string calldata tokenName, string calldata tokenSymbol, uint8 tokenDecimals) external;
}
