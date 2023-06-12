// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface IInterchainTokenExecutable {
    function exectuteWithInterchainToken(
        string calldata sourceChain,
        bytes calldata sourceAddress,
        // to mimic executeWithToken more maybe?
        bytes calldata data,
        bytes32 tokenId,
        uint256 amount
    ) external;

    function executeOnRevert() external view returns (bool);
}
