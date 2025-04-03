'use strict';

const MESSAGE_TYPE_INTERCHAIN_TRANSFER = 0;
const MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN = 1;
const MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER = 2;
const MESSAGE_TYPE_SEND_TO_HUB = 3;
const MESSAGE_TYPE_RECEIVE_FROM_HUB = 4;
const MESSAGE_TYPE_LINK_TOKEN = 5;
const MESSAGE_TYPE_REGISTER_TOKEN_METADATA = 6;
const INVALID_MESSAGE_TYPE = 7;

const NATIVE_INTERCHAIN_TOKEN = 0;
const MINT_BURN_FROM = 1;
const LOCK_UNLOCK = 2;
const LOCK_UNLOCK_FEE_ON_TRANSFER = 3;
const MINT_BURN = 4;

const MINTER_ROLE = 0;
const OPERATOR_ROLE = 1;
const FLOW_LIMITER_ROLE = 2;

// Chain name for ITS Hub chain
const ITS_HUB_CHAIN = 'axelar';
const ITS_HUB_ROUTING_IDENTIFIER = 'hub';
const ITS_HUB_ADDRESS = 'axelar12345678901234567890123456789012345678901234567890123456789';

module.exports = {
    MESSAGE_TYPE_INTERCHAIN_TRANSFER,
    MESSAGE_TYPE_DEPLOY_INTERCHAIN_TOKEN,
    MESSAGE_TYPE_DEPLOY_TOKEN_MANAGER,
    MESSAGE_TYPE_SEND_TO_HUB,
    MESSAGE_TYPE_RECEIVE_FROM_HUB,
    MESSAGE_TYPE_LINK_TOKEN,
    MESSAGE_TYPE_REGISTER_TOKEN_METADATA,
    INVALID_MESSAGE_TYPE,
    NATIVE_INTERCHAIN_TOKEN,
    MINT_BURN_FROM,
    LOCK_UNLOCK,
    LOCK_UNLOCK_FEE_ON_TRANSFER,
    MINT_BURN,
    MINTER_ROLE,
    OPERATOR_ROLE,
    FLOW_LIMITER_ROLE,
    ITS_HUB_CHAIN,
    ITS_HUB_ROUTING_IDENTIFIER,
    ITS_HUB_ADDRESS,
};
