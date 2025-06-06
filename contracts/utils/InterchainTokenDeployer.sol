// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IInterchainTokenDeployer } from '../interfaces/IInterchainTokenDeployer.sol';

import { HTS, IHederaTokenService } from '../hedera/HTS.sol';

/**
 * @title InterchainTokenDeployer
 * @notice This contract is used to deploy new instances of the InterchainTokenProxy contract.
 */
contract InterchainTokenDeployer is IInterchainTokenDeployer {
    /**
     * @notice Deploys a new instance of the InterchainTokenProxy contract.
     * @param tokenId TokenId for the token.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Decimals of the token.
     * @return tokenAddress Address of the deployed token.
     */
    function deployInterchainToken(
        bytes32 tokenId,
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) external payable returns (address tokenAddress) {
        // Since the caller uses delegatecall `this` refers to the calling contract
        address self = address(this);

        if (tokenId == bytes32(0)) revert TokenIdZero();
        if (bytes(name).length == 0) revert TokenNameEmpty();
        if (bytes(symbol).length == 0) revert TokenSymbolEmpty();

        IHederaTokenService.HederaToken memory token;
        token.name = name;
        token.symbol = symbol;
        token.treasury = self;

        // Set the token service as a minter to allow it to mint and burn tokens.
        IHederaTokenService.TokenKey[] memory tokenKeys = new IHederaTokenService.TokenKey[](1);
        // Define the supply keys - minter
        IHederaTokenService.KeyValue memory supplyKeyITS = IHederaTokenService.KeyValue({
            inheritAccountKey: false,
            contractId: self,
            ed25519: '',
            ECDSA_secp256k1: '',
            delegatableContractId: address(0)
        });
        tokenKeys[0] = IHederaTokenService.TokenKey({ keyType: HTS.SUPPLY_KEY_BIT, key: supplyKeyITS });
        token.tokenKeys = tokenKeys;

        // Set autoRenewPeriod to 0 so the default will be used (see `HTS.createFungibleToken`)
        // NOTE: Expiry is disabled on Hedera
        IHederaTokenService.Expiry memory expiry = IHederaTokenService.Expiry(0, self, 0);
        token.expiry = expiry;

        address createdTokenAddress = HTS.createFungibleToken(token, 0, int32(uint32(decimals)));

        tokenAddress = createdTokenAddress;
    }
}
