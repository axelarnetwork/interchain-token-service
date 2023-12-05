// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseInterchainToken } from '../interchain-token/BaseInterchainToken.sol';
import { Minter } from '../utils/Minter.sol';
import { IERC20MintableBurnable } from '../interfaces/IERC20MintableBurnable.sol';

contract TestFeeOnTransferToken is BaseInterchainToken, Minter, IERC20MintableBurnable {
    address public immutable service;
    bytes32 public tokenId;
    bool internal tokenManagerRequiresApproval_ = true;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address service_, bytes32 tokenId_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _addMinter(msg.sender);
        service = service_;
        tokenId = tokenId_;
    }

    function interchainTokenService() public view override returns (address) {
        return service;
    }

    function interchainTokenId() public view override returns (bytes32) {
        return tokenId;
    }

    function _beforeInterchainTransfer(
        address sender,
        string calldata /*destinationChain*/,
        bytes calldata /*destinationAddress*/,
        uint256 amount,
        bytes calldata /*metadata*/
    ) internal override {
        if (!tokenManagerRequiresApproval_) return;
        address serviceAddress = service;
        uint256 allowance_ = allowance[sender][serviceAddress];
        if (allowance_ != UINT256_MAX) {
            if (allowance_ > UINT256_MAX - amount) {
                allowance_ = UINT256_MAX - amount;
            }

            _approve(sender, serviceAddress, allowance_ + amount);
        }
    }

    function setTokenManagerRequiresApproval(bool requiresApproval) public {
        tokenManagerRequiresApproval_ = requiresApproval;
    }

    function mint(address account, uint256 amount) external onlyRole(uint8(Roles.MINTER)) {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyRole(uint8(Roles.MINTER)) {
        _burn(account, amount);
    }

    function setTokenId(bytes32 tokenId_) external {
        tokenId = tokenId_;
    }

    // Always transfer 10 less base tokens.
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (sender == address(0) || recipient == address(0)) revert InvalidAccount();

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount - 10;
        emit Transfer(sender, recipient, amount);
    }
}
