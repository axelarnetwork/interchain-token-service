// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ITokenHandler Interface
 * @notice This interface is responsible for handling tokens before initiating an interchain token transfer, or after receiving one.
 */
interface ITokenHandler {
    error UnsupportedTokenManagerType(uint256 tokenManagerType);
    error AddressZero();
    error NotToken(address caller, address token);
    error InvalidMetadataVersion(uint32 version);

    enum MetadataVersion {
        CONTRACT_CALL,
        EXPRESS_CALL
    }

    /**
     * @notice Returns the address of the axelar gateway on this chain.
     * @return gateway_ The address of the axelar gateway contract.
     */
    function gateway() external view returns (address gateway_);

    /**
     * @notice This function gives token to a specified address from the token manager.
     * @param tokenId The token id of the tokenManager.
     * @param to The address to give tokens to.
     * @param amount The amount of tokens to give.
     * @return uint256 The amount of token actually given, which could be different for certain token type.
     * @return address the address of the token.
     */
    function giveToken(bytes32 tokenId, address to, uint256 amount) external payable returns (uint256, address);

    /**
     * @notice This function takes token from a specified address to the token manager.
     * @param tokenId The tokenId for the token.
     * @param tokenOnly can only be called from the token.
     * @param from The address to take tokens from.
     * @param amount The amount of token to take.
     * @return uint256 The amount of token actually taken, which could be different for certain token type.
     * @return symbol The symbol for the token, if not empty the token is a gateway token and a callContractWith token has to be made.
     */
    // slither-disable-next-line locked-ether
    function takeToken(
        bytes32 tokenId,
        bool tokenOnly,
        address from,
        uint256 amount
    ) external payable returns (uint256, string memory symbol);

    /**
     * @notice This function transfers token from and to a specified address.
     * @param tokenId The token id of the token manager.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of token to transfer.
     * @return uint256 The amount of token actually transferred, which could be different for certain token type.
     * @return address The address of the token corresponding to the input tokenId.
     */
    // slither-disable-next-line locked-ether
    function transferTokenFrom(bytes32 tokenId, address from, address to, uint256 amount) external payable returns (uint256, address);

    /**
     * @notice This function prepares a token manager after it is deployed
     * @param tokenManagerType The token manager type.
     * @param tokenManager The address of the token manager.
     */
    function postTokenManagerDeploy(uint256 tokenManagerType, address tokenManager) external payable;

    /**
     * @notice This function pays gas to the gas service and calls the gateway to transmit a CallContract.
     * @param destinationChain The destination chain.
     * @param destinationAddress The destination address.
     * @param payload The payload to transmit.
     * @param metadataVersion The metadata version is used to determine how to pay for gas.
     * @param gasValue how much gas to pay.
     */
    function callContract(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable;

    /**
     * @notice This function pays gas to the gas service and calls the gateway to transmit a CallContractWithToken.
     * @param destinationChain The destination chain.
     * @param destinationAddress The destination address.
     * @param payload The payload to transmit.
     * @param metadataVersion The metadata version is used to determine how to pay for gas.
     * @param symbol The gateway symbol.
     * @param amount The amount of token to send.
     * @param gasValue how much gas to pay.
     */
    function callContractWithToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        MetadataVersion metadataVersion,
        uint256 gasValue
    ) external payable;
}
