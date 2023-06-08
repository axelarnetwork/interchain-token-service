// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { TokenManager } from '../TokenManager.sol';
import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';

abstract contract TokenManagerAddressStorage is TokenManager {
    constructor(
        address interchainTokenService_
    )
        // solhint-disable-next-line no-empty-blocks
        TokenManager(interchainTokenService_) // solhint-disable-next-line no-empty-blocks
    {}
    
    // uint256(keccak256('token-address')) - 1
    uint256 internal constant TOKEN_ADDRESS_SLOT = 0xc4e632779a6a7838736dd7e5e6a0eadf171dd37dfb6230720e265576dfcf42ba;

    function tokenAddress() public override view returns (address tokenAddress_) {
        assembly {
            tokenAddress_ := sload(TOKEN_ADDRESS_SLOT)
        }
    }

    function _setTokenAddress(address tokenAddress_) internal {
        assembly {
            sstore(TOKEN_ADDRESS_SLOT, tokenAddress_)
        }
    }
}
