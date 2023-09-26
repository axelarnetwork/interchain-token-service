// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20BurnableFrom {
    /**
     * @notice Function to get the burn deposit address for a particular salt
     * @notice It is needed to support legacy Axelar Gateway tokens
     * @param salt The salt used to generate the burn deposit address
     * @return address The burn deposit address
     */
    function depositAddress(bytes32 salt) external view returns (address);

    /**
     * @notice Function to burn tokens from a burn deposit address
     * @notice It is needed to support legacy Axelar Gateway tokens
     * @dev Can only be called after token is transferred to a deposit address.
     * @param salt The address that will have its tokens burnt
     */
    function burn(bytes32 salt) external;

    /**
     * @notice Function to burn tokens
     * @notice Requires the caller to have allowance for `amount` on `from`
     * @dev Can only be called by the distributor address.
     * @param from The address that will have its tokens burnt
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address from, uint256 amount) external;
}
