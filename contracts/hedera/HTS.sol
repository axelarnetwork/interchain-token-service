// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { HederaResponseCodes } from './HederaResponseCodes.sol';
import { IHederaTokenService } from './IHederaTokenService.sol';
import { IExchangeRate } from './IExchangeRate.sol';

/**
 * @title HTS
 * @notice This library provides a set of functions to interact with the Hedera Token Service (HTS).
 * It includes functionalities for creating, transferring, minting, and burning tokens, as well as querying token information and associating tokens with accounts.
 *
 * @dev This library includes a subset of the Hedera provided system library [HederaTokenService](https://github.com/hashgraph/hedera-smart-contracts/blob/bc3a549c0ca062c51b0045fd1916fdaa0558a360/contracts/system-contracts/hedera-token-service/HederaTokenService.sol).
 * Functions are modified to revert instead of returning response codes.
 * The library includes custom errors and additional functions.
 */
library HTS {
    address private constant PRECOMPILE = address(0x167);
    address private constant EXCHANGE_RATE_PRECOMPILE = address(0x168);

    // 1 whole is divided into 100_000_000 tiny parts
    // Applicable for tinybars and tinycents - used for exchange rate calculations
    uint256 constant TINY_PARTS_PER_WHOLE = 100_000_000;

    // See `TokenKey` struct, `keyType`.
    // 0th bit: adminKey
    uint256 internal constant ADMIN_KEY_BIT = 1 << 0;
    // 1st bit: kycKey
    uint256 internal constant KYC_KEY_BIT = 1 << 1;
    // 2nd bit: freezeKey
    uint256 internal constant FREEZE_KEY_BIT = 1 << 2;
    // 3rd bit: wipeKey
    uint256 internal constant WIPE_KEY_BIT = 1 << 3;
    // 4th bit: supplyKey
    uint256 internal constant SUPPLY_KEY_BIT = 1 << 4;
    // 5th bit: feeScheduleKey
    uint256 internal constant FEE_SCHEDULE_KEY_BIT = 1 << 5;
    // 6th bit: pauseKey
    uint256 internal constant PAUSE_KEY_BIT = 1 << 6;

    // 90 days in seconds
    int32 private constant DEFAULT_AUTO_RENEW = 7776000;

    /// @dev Thrown when the sender or receiver account is invalid.
    error InvalidAccount();

    /// @dev Thrown when the amount to mint/burn is invalid (negative or out of bounds).
    error InvalidAmount();

    /// @dev Thrown when the token decimals are invalid. Max value is uint8 (255).
    error InvalidTokenDecimals();

    /// @dev ITS cannot support KYC enabled tokens, or tokens with freeze, wipe or pause.
    error TokenUnsupported();

    /// @dev HTS EVM only supports a single minter, creating a token with initial supply is unsupported.
    error InitialSupplyUnsupported();

    /// @dev See HederaResponseCodes for a list of possible response codes.
    error HTSCallFailed(int32 responseCode);

    /// Query if valid token found for the given address
    /// @param token The token address
    /// @return isTokenFlag True if valid token found for the given address
    /// @dev This function reverts if the call is not successful
    function isToken(address token) public returns (bool isTokenFlag) {
        (bool success, bytes memory result) = PRECOMPILE.call(abi.encodeWithSelector(IHederaTokenService.isToken.selector, token));
        int32 responseCode;
        (responseCode, isTokenFlag) = success ? abi.decode(result, (int32, bool)) : (HederaResponseCodes.UNKNOWN, false);
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    /// Retrieves fungible specific token info for a fungible token
    /// @param token The ID of the token as a solidity address
    /// @return tokenInfo FungibleTokenInfo
    /// @dev This function reverts if the call is not successful
    function getFungibleTokenInfo(address token) public returns (IHederaTokenService.FungibleTokenInfo memory tokenInfo) {
        (bool success, bytes memory result) = PRECOMPILE.call(
            abi.encodeWithSelector(IHederaTokenService.getFungibleTokenInfo.selector, token)
        );
        IHederaTokenService.FungibleTokenInfo memory defaultTokenInfo;
        int32 responseCode;
        (responseCode, tokenInfo) = success
            ? abi.decode(result, (int32, IHederaTokenService.FungibleTokenInfo))
            : (HederaResponseCodes.UNKNOWN, defaultTokenInfo);
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    /// Creates a Fungible Token with the specified properties
    /// @param token the basic properties of the token being created
    /// @param initialTotalSupply Specifies the initial supply of tokens to be put in circulation. The
    /// initial supply is sent to the Treasury Account. The supply is in the lowest denomination possible.
    /// @param decimals the number of decimal places a token is divisible by
    /// @param price the amount to pay for token creation
    /// @return tokenAddress the created token's address
    function createFungibleToken(
        IHederaTokenService.HederaToken memory token,
        int64 initialTotalSupply,
        int32 decimals,
        uint256 price
    ) public returns (address tokenAddress) {
        if (token.expiry.second == 0 && token.expiry.autoRenewPeriod == 0) {
            token.expiry.autoRenewPeriod = DEFAULT_AUTO_RENEW;
        }

        (bool success, bytes memory result) = PRECOMPILE.call{ value: price }(
            abi.encodeWithSelector(IHederaTokenService.createFungibleToken.selector, token, initialTotalSupply, decimals)
        );

        int32 responseCode;
        (responseCode, tokenAddress) = success ? abi.decode(result, (int32, address)) : (HederaResponseCodes.UNKNOWN, address(0));

        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    /// Transfers tokens where the calling account/contract is implicitly the first entry in the token transfer list,
    /// where the amount is the value needed to zero balance the transfers. Regular signing rules apply for sending
    /// (positive amount) or receiving (negative amount)
    /// @param token The token to transfer to/from
    /// @param sender The sender for the transaction
    /// @param receiver The receiver of the transaction
    /// @param amount Non-negative value to send. a negative value will result in a failure.
    function transferToken(address token, address sender, address receiver, uint256 amount) public {
        if (amount > uint256(int256(type(int64).max))) {
            revert InvalidAmount();
        }
        if (sender == address(0) || receiver == address(0)) revert InvalidAccount();
        int64 amountInt64 = int64(int256(amount));
        (bool success, bytes memory result) = PRECOMPILE.call(
            abi.encodeWithSelector(IHederaTokenService.transferToken.selector, token, sender, receiver, amountInt64)
        );
        int32 responseCode;
        responseCode = success ? abi.decode(result, (int32)) : HederaResponseCodes.UNKNOWN;
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    /// Transfers `amount` tokens from `from` to `to` using the
    ///  allowance mechanism. `amount` is then deducted from the caller's allowance.
    /// Only applicable to fungible tokens
    /// @param token The address of the fungible Hedera token to transfer
    /// @param from The account address of the owner of the token, on the behalf of which to transfer `amount` tokens
    /// @param to The account address of the receiver of the `amount` tokens
    /// @param amount The amount of tokens to transfer from `from` to `to`
    function transferFrom(address token, address from, address to, uint256 amount) public {
        if (amount > uint256(int256(type(int64).max))) {
            revert InvalidAmount();
        }
        if (from == address(0) || to == address(0)) revert InvalidAccount();
        int64 amountInt64 = int64(int256(amount));
        (bool success, bytes memory result) = PRECOMPILE.call(
            abi.encodeWithSelector(IHederaTokenService.transferFrom.selector, token, from, to, amountInt64)
        );
        int32 responseCode;
        responseCode = success ? abi.decode(result, (int32)) : HederaResponseCodes.UNKNOWN;
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    /// Mints an amount of the token to the defined treasury account
    /// @param token The token for which to mint tokens. If token does not exist, transaction results in
    ///              INVALID_TOKEN_ID
    /// @param amount Applicable to tokens of type FUNGIBLE_COMMON. The amount to mint to the Treasury Account.
    ///               Amount must be a non-negative number represented in the lowest denomination of the
    ///               token. The new supply must be lower than 2^63.
    ///               Amount can be zero as per [HIP-564](https://hips.hedera.com/hip/hip-564).
    /// @return newTotalSupply The new supply of tokens. For NFTs it is the total count of NFTs
    function mintToken(address token, uint256 amount) public returns (int64 newTotalSupply) {
        if (amount > uint256(int256(type(int64).max))) {
            revert InvalidAmount();
        }

        bytes[] memory metadata;
        int64 amountInt64 = int64(int256(amount));
        (bool success, bytes memory result) = PRECOMPILE.call(
            abi.encodeWithSelector(IHederaTokenService.mintToken.selector, token, amountInt64, metadata)
        );
        int32 responseCode;
        (responseCode, newTotalSupply, ) = success
            ? abi.decode(result, (int32, int64, int64[]))
            : (HederaResponseCodes.UNKNOWN, int64(0), new int64[](0));
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    /// Burns an amount of the token from the defined treasury account
    /// @param token The token for which to burn tokens. If token does not exist, transaction results in
    ///              INVALID_TOKEN_ID
    /// @param amount  Applicable to tokens of type FUNGIBLE_COMMON. The amount to burn from the Treasury Account.
    ///                Amount must be a non-negative number, not bigger than the token balance of the treasury
    ///                account [0; balance], represented in the lowest denomination.
    ///                Amount can be zero as per [HIP-564](https://hips.hedera.com/hip/hip-564).
    /// @return newTotalSupply The new supply of tokens. For NFTs it is the total count of NFTs
    function burnToken(address token, uint256 amount) public returns (int64 newTotalSupply) {
        if (amount > uint256(int256(type(int64).max))) {
            revert InvalidAmount();
        }
        int64 amountInt64 = int64(int256(amount));
        int64[] memory serialNumbers;
        (bool success, bytes memory result) = PRECOMPILE.call(
            abi.encodeWithSelector(IHederaTokenService.burnToken.selector, token, amountInt64, serialNumbers)
        );
        int32 responseCode;
        (responseCode, newTotalSupply) = success ? abi.decode(result, (int32, int64)) : (HederaResponseCodes.UNKNOWN, int64(0));
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    ///  Associates the provided account with the provided tokens. Must be signed by the provided
    ///  Account's key or called from the accounts contract key
    ///  If the provided account is not found, the transaction will resolve to INVALID_ACCOUNT_ID.
    ///  If the provided account has been deleted, the transaction will resolve to ACCOUNT_DELETED.
    ///  If any of the provided tokens is not found, the transaction will resolve to INVALID_TOKEN_REF.
    ///  If any of the provided tokens has been deleted, the transaction will resolve to TOKEN_WAS_DELETED.
    ///  If an association between the provided account and any of the tokens already exists, the
    ///  transaction resolves to TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT, but the function doesn't revert.
    ///  If the provided account's associations count exceed the constraint of maximum token associations
    ///    per account, the transaction will resolve to TOKENS_PER_ACCOUNT_LIMIT_EXCEEDED.
    ///  On success, associations between the provided account and tokens are made and the account is
    ///    ready to interact with the tokens.
    /// @param account The account to be associated with the provided tokens
    /// @param token The token to be associated with the provided account.
    function associateToken(address account, address token) public {
        (bool success, bytes memory result) = PRECOMPILE.call(
            abi.encodeWithSelector(IHederaTokenService.associateToken.selector, account, token)
        );
        int32 responseCode;
        responseCode = success ? abi.decode(result, (int32)) : HederaResponseCodes.UNKNOWN;
        // If the token is already associated to the account, we don't need to do anything (ie. we don't revert)
        if (responseCode == HederaResponseCodes.TOKEN_ALREADY_ASSOCIATED_TO_ACCOUNT) {
            return;
        }
        if (responseCode != HederaResponseCodes.SUCCESS) {
            revert HTSCallFailed(responseCode);
        }
    }

    //
    // Exchange rate functionality
    //

    function centsToTinybars(uint256 cents) public returns (uint256 tinybars) {
        uint256 tinycents = cents * TINY_PARTS_PER_WHOLE;

        (bool success, bytes memory result) = EXCHANGE_RATE_PRECOMPILE.call(
            abi.encodeWithSelector(IExchangeRate.tinycentsToTinybars.selector, tinycents)
        );
        require(success);
        tinybars = abi.decode(result, (uint256));
    }

    function tinycentsToTinybars(uint256 tinycents) public returns (uint256 tinybars) {
        (bool success, bytes memory result) = EXCHANGE_RATE_PRECOMPILE.call(
            abi.encodeWithSelector(IExchangeRate.tinycentsToTinybars.selector, tinycents)
        );
        require(success);
        tinybars = abi.decode(result, (uint256));
    }

    //
    // Extra functionality
    //

    /// Checks if the Token is supported by ITS.
    /// @param token The token address to check.
    /// @return supported If the token is supported.
    function isTokenSupportedByITS(address token) public returns (bool supported) {
        IHederaTokenService.FungibleTokenInfo memory fTokenInfo = getFungibleTokenInfo(token);

        bool hasUnsupportedKeys = false;
        for (uint256 i = 0; i < fTokenInfo.tokenInfo.token.tokenKeys.length; i++) {
            uint256 keyType = fTokenInfo.tokenInfo.token.tokenKeys[i].keyType;

            // Check if the key in question is one that we care about
            if ((keyType & (KYC_KEY_BIT | FREEZE_KEY_BIT | WIPE_KEY_BIT | PAUSE_KEY_BIT)) != 0) {
                IHederaTokenService.KeyValue memory keyValue = fTokenInfo.tokenInfo.token.tokenKeys[i].key;

                // Check if it has any value for the key
                // If it does, the token is not supported
                if (
                    keyValue.inheritAccountKey ||
                    keyValue.contractId != address(0) ||
                    keyValue.ed25519.length != 0 ||
                    keyValue.ECDSA_secp256k1.length != 0 ||
                    keyValue.delegatableContractId != address(0)
                ) {
                    hasUnsupportedKeys = true;
                    break;
                }
            }
        }

        return !hasUnsupportedKeys;
    }
}
