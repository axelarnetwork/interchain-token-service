// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenManager } from '../TokenManager.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';

/**
 * @title TokenManagerAddressStorage
 * @notice This contract extends the TokenManager contract and provides additional functionality to store and retrieve
 * the token address using a predetermined storage slot
 */
abstract contract TokenManagerAddressStorage is TokenManager {
    // uint256(keccak256('token-address')) - 1
    uint256 internal constant TOKEN_ADDRESS_SLOT = 0xc4e632779a6a7838736dd7e5e6a0eadf171dd37dfb6230720e265576dfcf42ba;

    /**
     * @dev Creates an instance of the TokenManagerAddressStorage contract.
     * @param interchainTokenService_ The address of the interchain token service contract
     */
    constructor(address interchainTokenService_) TokenManager(interchainTokenService_) {}

    /**
     * @dev Reads the stored token address from the predetermined storage slot
     * @return tokenAddress_ The address of the token
     */
    function tokenAddress() public view override returns (address tokenAddress_) {
        assembly {
            tokenAddress_ := sload(TOKEN_ADDRESS_SLOT)
        }
    }

    /**
     * @dev Stores the token address in the predetermined storage slot
     * @param tokenAddress_ The address of the token to store
     */
    function _setTokenAddress(address tokenAddress_) internal {
        assembly {
            sstore(TOKEN_ADDRESS_SLOT, tokenAddress_)
        }
    }
}
