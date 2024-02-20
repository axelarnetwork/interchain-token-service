// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Create3AddressFixed contract
 * @notice This contract can be used to predict the deterministic deployment address of a contract deployed with the `CREATE3` technique.
 * It is equivalent to the Create3Address found in axelar-sdk-solidity but uses a fixed bytecode for CreateDeploy,
 * which allows changing compilation options (like number of runs) without affecting the future deployment addresses.
 */
contract Create3AddressFixed {
    // slither-disable-next-line too-many-digits
    bytes internal constant CREATE_DEPLOY_BYTECODE =
        hex'608060405234801561001057600080fd5b50610162806100206000396000f3fe60806040526004361061001d5760003560e01c806277436014610022575b600080fd5b61003561003036600461007b565b610037565b005b8051602082016000f061004957600080fd5b50565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b60006020828403121561008d57600080fd5b813567ffffffffffffffff808211156100a557600080fd5b818401915084601f8301126100b957600080fd5b8135818111156100cb576100cb61004c565b604051601f8201601f19908116603f011681019083821181831017156100f3576100f361004c565b8160405282815287602084870101111561010c57600080fd5b82602086016020830137600092810160200192909252509594505050505056fea264697066735822122094780ce55d28f1d568f4e0ab1b9dc230b96e952b73d2e06456fbff2289fa27f464736f6c63430008150033';
    bytes32 internal constant CREATE_DEPLOY_BYTECODE_HASH = keccak256(CREATE_DEPLOY_BYTECODE);

    /**
     * @notice Compute the deployed address that will result from the `CREATE3` method.
     * @param deploySalt A salt to influence the contract address
     * @return deployed The deterministic contract address if it was deployed
     */
    function _create3Address(bytes32 deploySalt) internal view returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex'ff', address(this), deploySalt, CREATE_DEPLOY_BYTECODE_HASH))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex'd6_94', deployer, hex'01')))));
    }
}
