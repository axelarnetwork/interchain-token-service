// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title StandardizedTokenProxy
 * @dev Proxy contract for StandardizedToken contracts. Inherits from FixedProxy and implements IStandardizedTokenProxy.
 */
interface IStandardizedTokenProxy {
    error WrongImplementation();

    /**
     * @notice Returns the contract id, which a proxy can check to ensure no false implementation was used.
     */
    function contractId() external view returns (bytes32);
}
