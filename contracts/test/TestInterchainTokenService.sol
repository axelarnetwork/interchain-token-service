// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainTokenService } from '../InterchainTokenService.sol';

contract TestInterchainTokenService is InterchainTokenService {
    error LatestMetadataVersionMismatch(uint32 const, uint32 calculated);

    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address interchainTokenFactory_,
        string memory chainName_,
        address tokenManager_,
        address tokenHandler_
    )
        InterchainTokenService(
            tokenManagerDeployer_,
            interchainTokenDeployer_,
            gateway_,
            interchainTokenFactory_,
            chainName_,
            tokenManager_,
            tokenHandler_
        )
    {
        if (LATEST_METADATA_VERSION != uint32(type(MetadataVersion).max))
            revert LatestMetadataVersionMismatch(LATEST_METADATA_VERSION, uint32(type(MetadataVersion).max));
    }

    function setupTest(bytes calldata params) external {
        _setup(params);
    }

    function callContract(
        string calldata destinationChain,
        bytes memory payload,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable {
        _callContract(destinationChain, payload, metadataVersion, gasValue);
    }
}
