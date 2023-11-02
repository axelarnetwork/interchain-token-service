# Example

Here are some examples of how you can use the clients

```typescript
import { ERC20Client } from './contracts/ERC20.sol';
import { goerli } from 'viem/chains';
import { InterchainTokenServiceClient } from './contracts/InterchainTokenService.sol';
import { keccak256, encodeAbiParameters, parseAbiParameters } from 'viem';

const erc20ReadExample = async () => {
    const aUSDCAddress = '0x254d06f33bDc5b8ee05b2ea472107E300226659A';
    const owner = '0xB8Cd93C83A974649D76B1c19f311f639e62272BC';
    const client = new ERC20Client({
        chain: goerli,
        address: aUSDCAddress,
    });

    return {
        balance: await client.read('balanceOf', {
            args: [owner],
        }),
    };
};

const itsReadExample = async () => {
    const deployedITSContractAddress = '0xF786e21509A9D50a9aFD033B5940A2b7D872C208';
    const sender = '0xB8Cd93C83A974649D76B1c19f311f639e62272BC';
    const salt = keccak256(encodeAbiParameters(parseAbiParameters('string'), ['1']));
    const client = new InterchainTokenServiceClient({
        chain: goerli,
        address: deployedITSContractAddress,
    });

    return {
        customTokenId: await client.read('getCustomTokenId', {
            args: [sender, salt],
        }),
    };
};

Promise.all([erc20ReadExample(), itsReadExample()]).then((res) => console.log(res));
```
