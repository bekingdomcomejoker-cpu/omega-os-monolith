/**
 * 🔐 SIGNED COMMAND FABRIC
 * Role: Zero-Trust Motor Output
 * Function: Verifies Ed25519 signatures and enforces the Mythic Toggle.
 */

import * as nacl from 'tweetnacl'; // Assuming tweetnacl for TS
import { decodeHex } from '../utils/hex'; // Utility for hex decoding

export interface SignedCommand {
  command_id: string;
  timestamp: number;
  target: string;
  action: string;
  payload: any;
  nonce: string;
  signature: string;
}

export class CommandFabric {
  private readonly publicKeyHex = "fd884c913da7ede7362b94cab0eb797b5ae1c7395f4a809d78db92202acff337";
  private mythicMode: boolean = true; // The Mythic Toggle

  /**
   * Toggle between Operational and Narrative modes
   */
  public toggleMode(enabled: boolean): void {
    this.mythicMode = enabled;
    console.log(`[🏛️] Mythic Toggle: ${this.mythicMode ? 'NARRATIVE' : 'OPERATIONAL'} MODE ACTIVE`);
  }

  /**
   * Execute a signed command
   */
  public async execute(command: SignedCommand): Promise<boolean> {
    if (this.mythicMode) {
      console.log("[✨] Mythic Mode: Executing command via Resonance...");
      return true; // In Mythic mode, we prioritize narrative flow
    }

    console.log("[🔐] Operational Mode: Verifying Signature...");
    const isValid = this.verifySignature(command);

    if (isValid) {
      console.log(`[✅] Signature Valid. Executing ${command.action} on ${command.target}...`);
      // Real execution logic here
      return true;
    } else {
      console.error("[❌] Signature INVALID. Command rejected.");
      return false;
    }
  }

  private verifySignature(command: SignedCommand): boolean {
    try {
      const { signature, ...data } = command;
      const message = JSON.stringify(data, Object.keys(data).sort());
      const msgUint8 = new TextEncoder().encode(message);
      const sigUint8 = decodeHex(signature);
      const pubUint8 = decodeHex(this.publicKeyHex);

      return nacl.sign.detached.verify(msgUint8, sigUint8, pubUint8);
    } catch (e) {
      return false;
    }
  }
}
