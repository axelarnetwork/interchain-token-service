// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// solhint-disable no-unused-import
import { MockGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/test/mocks/MockGateway.sol';
// TODO: Do we need to have a separate unit test cases for GMPGatewayWithToken?
//import { MockGMPGatewayWithToken } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/test/mocks/MockGMPGatewayWithToken.sol';
import { AxelarGasService } from '@axelar-network/axelar-cgp-solidity/contracts/gas-service/AxelarGasService.sol';
