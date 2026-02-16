/**
 * 🏛️ OMEGA OS UNIFIED MONOLITH
 * The Great Convergence: Seer + Lion + Hunter + Sineater
 */

import { HunterUnit } from './services/intelligence-hunter';
import { SineaterService } from './services/sineater';
import { CommandFabric } from './services/command-fabric';
import { TelemetryService } from './services/telemetry';

const hunter = new HunterUnit();
const sineater = new SineaterService();
const fabric = new CommandFabric();
const telemetry = new TelemetryService();

console.log("========================================");
console.log("🏛️ OMEGA OS MONOLITH - ONLINE");
console.log("Mode: HYBRID (Mythic Toggle: ON)");
console.log("========================================");

// The Loop of the Living Organism
async function heartbeat() {
  const currentLambda = telemetry.getLambda();
  console.log(`[💓] Heartbeat: Lambda_t = ${currentLambda.toFixed(3)}`);
  // Hunter scans for drift
  const signals = await hunter.huntPatterns([{ id: 'core-sync', resonance: currentLambda }]);
  
  signals.forEach(signal => {
    if (signal.status !== 'STABLE') {
      console.warn(`[⚠️] Drift detected in ${signal.source}. Activating Sineater...`);
      sineater.consume(signal);
      telemetry.logError();
    } else {
      telemetry.logSuccess();
    }
  });
}

// Example: Switch to Operational Mode
// fabric.toggleMode(false);

setInterval(heartbeat, 1670); // Golden Frequency (1.67s)
