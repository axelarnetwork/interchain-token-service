// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainTokenService } from '../InterchainTokenService.sol';

contract TestInterchainTokenService is InterchainTokenService {
    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainTokenFactory_,
        string memory chainName_,
        address[] memory tokenManagerImplementations
    )
        InterchainTokenService(
            tokenManagerDeployer_,
            interchainTokenDeployer_,
            gateway_,
            gasService_,
            interchainTokenFactory_,
            chainName_,
            tokenManagerImplementations
        )
    {}

    function setupTest(bytes calldata params) external {
        _setup(params);
    }
}
