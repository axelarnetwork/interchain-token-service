// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EVMInterchainTokenService } from '../evm/EVMInterchainTokenService.sol';
import { HederaInterchainTokenService } from '../hedera/HederaInterchainTokenService.sol';
import { HyperliquidInterchainTokenService } from '../hyperliquid/HyperliquidInterchainTokenService.sol';

/**
 * @title Interchain Token Service Factory
 * @notice Factory contract for deploying chain-specific Interchain Token Service implementations
 * @dev Supports EVM, Hedera, and Hyperliquid deployments
 */
contract InterchainTokenServiceFactory {
    enum ChainType {
        EVM,
        HEDERA,
        HYPERLIQUID
    }

    /**
     * @notice Event emitted when a new ITS is deployed
     * @param chainType The type of chain
     * @param itsAddress The deployed ITS address
     * @param chainName The chain name
     */
    event InterchainTokenServiceDeployed(
        ChainType indexed chainType,
        address indexed itsAddress,
        string chainName
    );

    /**
     * @notice Deploy EVM Interchain Token Service
     */
    function deployEVMInterchainTokenService(
        address tokenManagerDeployer,
        address interchainTokenDeployer,
        address gateway,
        address gasService,
        address interchainTokenFactory,
        string memory chainName,
        string memory itsHubAddress,
        address tokenManagerImplementation,
        address tokenHandler
    ) external returns (address itsAddress) {
        EVMInterchainTokenService its = new EVMInterchainTokenService(
            tokenManagerDeployer,
            interchainTokenDeployer,
            gateway,
            gasService,
            interchainTokenFactory,
            chainName,
            itsHubAddress,
            tokenManagerImplementation,
            tokenHandler
        );

        emit InterchainTokenServiceDeployed(ChainType.EVM, address(its), chainName);
        return address(its);
    }

    /**
     * @notice Deploy Hedera Interchain Token Service
     */
    function deployHederaInterchainTokenService(
        address tokenManagerDeployer,
        address interchainTokenDeployer,
        address gateway,
        address gasService,
        address interchainTokenFactory,
        string memory chainName,
        string memory itsHubAddress,
        address tokenManagerImplementation,
        address tokenHandler,
        address whbarAddress
    ) external returns (address itsAddress) {
        HederaInterchainTokenService its = new HederaInterchainTokenService(
            tokenManagerDeployer,
            interchainTokenDeployer,
            gateway,
            gasService,
            interchainTokenFactory,
            chainName,
            itsHubAddress,
            tokenManagerImplementation,
            tokenHandler,
            whbarAddress
        );

        emit InterchainTokenServiceDeployed(ChainType.HEDERA, address(its), chainName);
        return address(its);
    }

    /**
     * @notice Deploy Hyperliquid Interchain Token Service
     */
    function deployHyperliquidInterchainTokenService(
        address tokenManagerDeployer,
        address interchainTokenDeployer,
        address gateway,
        address gasService,
        address interchainTokenFactory,
        string memory chainName,
        string memory itsHubAddress,
        address tokenManagerImplementation,
        address tokenHandler
    ) external returns (address itsAddress) {
        HyperliquidInterchainTokenService its = new HyperliquidInterchainTokenService(
            tokenManagerDeployer,
            interchainTokenDeployer,
            gateway,
            gasService,
            interchainTokenFactory,
            chainName,
            itsHubAddress,
            tokenManagerImplementation,
            tokenHandler
        );

        emit InterchainTokenServiceDeployed(ChainType.HYPERLIQUID, address(its), chainName);
        return address(its);
    }

    /**
     * @notice Deploy ITS based on chain type
     */
    function deployInterchainTokenService(
        ChainType chainType,
        address tokenManagerDeployer,
        address interchainTokenDeployer,
        address gateway,
        address gasService,
        address interchainTokenFactory,
        string memory chainName,
        string memory itsHubAddress,
        address tokenManagerImplementation,
        address tokenHandler,
        address whbarAddress
    ) external returns (address itsAddress) {
        if (chainType == ChainType.EVM) {
            return deployEVMInterchainTokenService(
                tokenManagerDeployer,
                interchainTokenDeployer,
                gateway,
                gasService,
                interchainTokenFactory,
                chainName,
                itsHubAddress,
                tokenManagerImplementation,
                tokenHandler
            );
        } else if (chainType == ChainType.HEDERA) {
            return deployHederaInterchainTokenService(
                tokenManagerDeployer,
                interchainTokenDeployer,
                gateway,
                gasService,
                interchainTokenFactory,
                chainName,
                itsHubAddress,
                tokenManagerImplementation,
                tokenHandler,
                whbarAddress
            );
        } else if (chainType == ChainType.HYPERLIQUID) {
            return deployHyperliquidInterchainTokenService(
                tokenManagerDeployer,
                interchainTokenDeployer,
                gateway,
                gasService,
                interchainTokenFactory,
                chainName,
                itsHubAddress,
                tokenManagerImplementation,
                tokenHandler
            );
        } else {
            revert UnsupportedChainType();
        }
    }

    // ============ Error Definitions ============

    error UnsupportedChainType();
} 