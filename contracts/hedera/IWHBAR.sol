// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IWHBAR
 * @notice Interface for the Wrapped HBAR (WHBAR) contract
 */
interface IWHBAR {
    /**
     * @notice Emitted when HBAR is deposited and WHBAR is minted
     * @param dst The address that received the WHBAR
     * @param wad The amount of WHBAR minted
     */
    event Deposit(address indexed dst, uint wad);

    /**
     * @notice Emitted when WHBAR is burned and HBAR is withdrawn
     * @param src The address that burned the WHBAR
     * @param wad The amount of WHBAR burned
     */
    event Withdrawal(address indexed src, uint wad);

    /**
     * @notice Emitted when approval is set
     * @param src The owner address
     * @param guy The spender address
     * @param wad The approved amount
     */
    event Approval(address indexed src, address indexed guy, uint wad);

    /**
     * @notice Emitted when tokens are transferred
     * @param src The sender address
     * @param dst The receiver address
     * @param wad The amount transferred
     */
    event Transfer(address indexed src, address indexed dst, uint wad);

    /**
     * @notice Error thrown when account has insufficient funds
     */
    error InsufficientFunds();

    /**
     * @notice Error thrown when spender has insufficient allowance
     */
    error InsufficientAllowance();

    /**
     * @notice Error thrown when HBAR transfer fails
     */
    error SendFailed();

    /**
     * @notice Returns the name of the token
     * @return The token name
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the token
     * @return The token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Returns the number of decimals
     * @return The number of decimals
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Returns the total supply of WHBAR
     * @return The total supply
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the balance of an account
     * @param user The address to query
     * @return The balance of the account
     */
    function balanceOf(address user) external view returns (uint);

    /**
     * @notice Returns the allowance of a spender for an owner
     * @param owner The owner address
     * @param spender The spender address
     * @return The allowance amount
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @notice Deposits HBAR and mints WHBAR to the sender
     */
    function deposit() external payable;

    /**
     * @notice Withdraws HBAR by burning WHBAR
     * @param wad The amount of WHBAR to burn
     */
    function withdraw(uint wad) external;

    /**
     * @notice Approves a spender to transfer tokens on behalf of the caller
     * @param guy The spender address
     * @param wad The amount to approve
     * @return True if successful
     */
    function approve(address guy, uint wad) external returns (bool);

    /**
     * @notice Transfers tokens to a recipient
     * @param dst The recipient address
     * @param wad The amount to transfer
     * @return True if successful
     */
    function transfer(address dst, uint wad) external returns (bool);

    /**
     * @notice Transfers tokens from one address to another using allowance
     * @param src The sender address
     * @param dst The recipient address
     * @param wad The amount to transfer
     * @return True if successful
     */
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}