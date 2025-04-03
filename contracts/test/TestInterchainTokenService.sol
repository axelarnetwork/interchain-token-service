// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IGatewayCaller } from '../interfaces/IGatewayCaller.sol';
import { InterchainTokenService } from '../InterchainTokenService.sol';

contract TestInterchainTokenService is InterchainTokenService {
    error LatestMetadataVersionMismatch(uint32 const, uint32 calculated);

    constructor(
        address tokenManagerDeployer_,
        address interchainTokenDeployer_,
        address gateway_,
        address gasService_,
        address interchainTokenFactory_,
        string memory chainName_,
        string memory itsHubAddress_,
        address tokenManager_,
        address tokenHandler_,
        address gatewayCaller_
    )
        InterchainTokenService(
            tokenManagerDeployer_,
            interchainTokenDeployer_,
            gateway_,
            gasService_,
            interchainTokenFactory_,
            chainName_,
            itsHubAddress_,
            tokenManager_,
            tokenHandler_,
            gatewayCaller_
        )
    {
        if (LATEST_METADATA_VERSION != uint32(type(IGatewayCaller.MetadataVersion).max))
            revert LatestMetadataVersionMismatch(LATEST_METADATA_VERSION, uint32(type(IGatewayCaller.MetadataVersion).max));
    }

    function setTrustedAddress(string calldata chainName, string calldata trustedAddress_) external {
        _setTrustedAddress(chainName, trustedAddress_);
    }

    function setupTest(bytes calldata params) external {
        _setup(params);
    }
}
