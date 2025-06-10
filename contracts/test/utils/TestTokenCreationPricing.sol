// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { TokenCreationPricing } from '../../utils/TokenCreationPricing.sol';

contract TestTokenCreationPricing is TokenCreationPricing {
    error Invalid();

    constructor() {
        if (TOKEN_CREATION_PRICING_SLOT != uint256(keccak256('TokenCreationPricing.Slot')) - 1) revert Invalid();
    }

    function setTokenCreationPriceTest(uint256 price) external {
        _setTokenCreationPrice(price);
    }

    function setWhbarAddressTest(address whbarAddress_) external {
        _setWhbarAddress(whbarAddress_);
    }

    function getTokenCreationPricingSlot() external pure returns (uint256) {
        return TOKEN_CREATION_PRICING_SLOT;
    }

    function calculateExpectedSlot() external pure returns (uint256) {
        return uint256(keccak256('TokenCreationPricing.Slot')) - 1;
    }
}
