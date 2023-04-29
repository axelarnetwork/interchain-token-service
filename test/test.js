const { createNetwork, deployContract } = require("@axelar-network/axelar-local-dev");
const { deployTokenService } = require("../scripts/deploy");


(async() => {
    const network = await createNetwork();
    const [wallet] = network.userWallets
    await deployTokenService()
})();