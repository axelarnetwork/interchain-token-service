// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { FinalProxy } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/FinalProxy.sol';

contract InterchainTokenServiceProxy is FinalProxy {
    constructor(
        address implementationAddress,
        address owner,
        bytes memory /*setupParams*/
    )
        FinalProxy(implementationAddress, owner, new bytes(0)) // solhint-disable-next-line no-empty-blocks
    {}

    // solhint-disable-next-line no-empty-blocks
    function contractId() internal pure override returns (bytes32) {
        // keccak256('interchain-token-service')-1
        return 0xf407da03daa7b4243ffb261daad9b01d221ea90ab941948cd48101563654ea85;
    }
}
