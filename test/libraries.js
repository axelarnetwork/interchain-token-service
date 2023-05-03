const { createNetwork, deployContract } = require('@axelar-network/axelar-local-dev');
const LibrariesTest = require('../artifacts/contracts/test/LibrariesTest.sol/LibrariesTest.json');
const { expect } = require('chai');

describe('Libraries Test', () => {
    let contract, wallet;

    before(async () => {
        const network = await createNetwork();
        [wallet] = network.userWallets;
        contract = await deployContract(wallet, LibrariesTest, []);
    });
    it('Should convert address to bytes', async () => {
        expect(await contract.addressToBytes(wallet.address)).to.equal(wallet.address.toLowerCase());
    });
});
