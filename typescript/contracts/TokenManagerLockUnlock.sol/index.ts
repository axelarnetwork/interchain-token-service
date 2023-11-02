/* eslint-disable @typescript-eslint/no-explicit-any */
/**
 * This file was generated by scripts/codegen.ts
 *
 * Original abi file:
 * - dist/TokenManagerLockUnlock.sol/TokenManagerLockUnlock.sol/TokenManagerLockUnlock.json
 *
 * DO NOT EDIT MANUALLY
 */

import { Chain } from "viem";

import { PublicContractClient } from "../../client/PublicContractClient";
import ABI_FILE from "./TokenManagerLockUnlock.abi";

export * from "./TokenManagerLockUnlock.args";

export const TOKENMANAGERLOCKUNLOCK_ABI = ABI_FILE.abi;

export class TokenManagerLockUnlockClient extends PublicContractClient<
  typeof ABI_FILE.abi
> {
  static ABI = ABI_FILE.abi;
  static contractName = ABI_FILE.contractName;

  constructor(options: { chain: Chain; address: `0x${string}` }) {
    super({
      abi: TOKENMANAGERLOCKUNLOCK_ABI,
      address: options.address,
      chain: options.chain,
    });
  }
}
