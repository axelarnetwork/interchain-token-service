/* eslint-disable @typescript-eslint/no-explicit-any */
/**
 * This file was generated by scripts/codegen.ts
 *
 * Original abi file:
 * - dist/StandardizedTokenMintBurn.sol/StandardizedTokenMintBurn.sol/StandardizedTokenMintBurn.json
 *
 * DO NOT EDIT MANUALLY
 */

import { Chain } from "viem";

import { PublicContractClient } from "../../client/PublicContractClient";
import ABI_FILE from "./StandardizedTokenMintBurn.abi";

export * from "./StandardizedTokenMintBurn.args";

export const STANDARDIZEDTOKENMINTBURN_ABI = ABI_FILE.abi;

export class StandardizedTokenMintBurnClient extends PublicContractClient<
  typeof ABI_FILE.abi
> {
  static ABI = ABI_FILE.abi;
  static contractName = ABI_FILE.contractName;

  constructor(options: { chain: Chain; address: `0x${string}` }) {
    super({
      abi: STANDARDIZEDTOKENMINTBURN_ABI,
      address: options.address,
      chain: options.chain,
    });
  }
}
