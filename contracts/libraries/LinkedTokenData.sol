// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library LinkedTokenData {
    error SymbolTooLong();

    bytes32 public constant IS_ORIGIN_MASK = bytes32(uint256(0x80 << 248));
    bytes32 public constant IS_GATEWAY_MASK = bytes32(uint256(0x40 << 248));
    bytes32 public constant IS_REMOTE_GATEWAY_MASK = bytes32(uint256(0x20 << 248));
    bytes32 public constant LENGTH_MASK = bytes32(uint256(0x0f << 248));

    function getAddress(bytes32 tokenData) internal pure returns (address) {
        return address(uint160(uint256((tokenData))));
    }

    function isOrigin(bytes32 tokenData) internal pure returns (bool) {
        return tokenData & IS_ORIGIN_MASK == IS_ORIGIN_MASK;
    }

    function isGateway(bytes32 tokenData) internal pure returns (bool) {
        return tokenData & IS_GATEWAY_MASK == IS_GATEWAY_MASK;
    }

    function isRemoteGateway(bytes32 tokenData) internal pure returns (bool) {
        return tokenData & IS_REMOTE_GATEWAY_MASK == IS_REMOTE_GATEWAY_MASK;
    }

    function getSymbolLength(bytes32 tokenData) internal pure returns (uint256) {
        return uint256((tokenData & LENGTH_MASK) >> 248);
    }

    function getSymbol(bytes32 tokenData) internal pure returns (string memory symbol) {
        uint256 length = getSymbolLength(tokenData);
        symbol = new string(length);
        bytes32 stringData = tokenData << 8;
        assembly {
            mstore(add(symbol, 0x20), stringData)
        }
    }

    function createTokenData(address tokenAddress, bool origin) internal pure returns (bytes32 tokenData) {
        tokenData = bytes32(uint256(uint160(tokenAddress)));
        if (origin) tokenData |= IS_ORIGIN_MASK;
    }

    function createGatewayTokenData(address tokenAddress, bool origin, string memory symbol) internal pure returns (bytes32 tokenData) {
        tokenData = bytes32(uint256(uint160(tokenAddress))) | IS_GATEWAY_MASK;
        if (origin) tokenData |= IS_ORIGIN_MASK;
        uint256 length = bytes(symbol).length;
        if (length > 11) revert SymbolTooLong();

        tokenData |= bytes32(length) << 248;
        bytes32 symbolData = bytes32(bytes(symbol)) >> 8;
        tokenData |= symbolData;
    }

    function createRemoteGatewayTokenData(address tokenAddress) internal pure returns (bytes32 tokenData) {
        tokenData = bytes32(uint256(uint160(tokenAddress))) | IS_REMOTE_GATEWAY_MASK;
    }
}
