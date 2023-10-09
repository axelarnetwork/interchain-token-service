// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { IERC20Permit } from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IERC20Permit.sol';

import { ERC20 } from './ERC20.sol';

/**
 * @title ERC20Permit Contract
 * @dev Extension of ERC20 to include permit functionality (EIP-2612).
 * Allows for approval of ERC20 tokens by signature rather than transaction.
 */
abstract contract ERC20Permit is IERC20, IERC20Permit, ERC20 {
    error PermitExpired();
    error InvalidS();
    error InvalidV();
    error InvalidSignature();

    /**
     * @dev Represents hash of the EIP-712 Domain Separator.
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public nameHash;

    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = '\x19\x01';

    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
    bytes32 private constant DOMAIN_TYPE_SIGNATURE_HASH = bytes32(0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f);

    // keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')
    bytes32 private constant PERMIT_SIGNATURE_HASH = bytes32(0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9);

    /**
     * @dev Mapping of nonces for each address.
     */
    mapping(address => uint256) public nonces;

    /**
     * @notice Internal function to set the token name hash
     * @param name The token name
     */
    function _setNameHash(string memory name) internal {
        nameHash = keccak256(bytes(name));
    }

    /**
     * @notice Calculates the DOMAIN_SEPARATOR.
     * @dev This is not cached because chainid can change on chain forks.
     */
    // slither-disable-next-line naming-convention
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        // solhint-disable-line func-name-mixedcase
        domainSeparator = keccak256(abi.encode(DOMAIN_TYPE_SIGNATURE_HASH, nameHash, keccak256(bytes('1')), block.chainid, address(this)));
    }

    /**
     * @notice Permit the designated spender to spend the holder's tokens
     * @dev The permit function is used to allow a holder to designate a spender
     * to spend tokens on their behalf via a signed message.
     * @param issuer The address of the token holder
     * @param spender The address of the designated spender
     * @param value The number of tokens to be spent
     * @param deadline The time at which the permission to spend expires
     * @param v The recovery id of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address issuer, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        if (block.timestamp > deadline) revert PermitExpired();

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert InvalidS();

        if (v != 27 && v != 28) revert InvalidV();

        bytes32 digest = keccak256(
            abi.encodePacked(
                EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_SIGNATURE_HASH, issuer, spender, value, nonces[issuer]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);

        if (recoveredAddress != issuer) revert InvalidSignature();

        // _approve will revert if issuer is address(0x0)
        _approve(issuer, spender, value);
    }
}
