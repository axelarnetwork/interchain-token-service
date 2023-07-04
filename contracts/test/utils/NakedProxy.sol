// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NakedProxy {
    address public immutable implementation;

    constructor(address implementation_) {
        implementation = implementation_;
    }

    fallback() external payable virtual {
        address implementaion_ = implementation;

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementaion_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable virtual {}
}
