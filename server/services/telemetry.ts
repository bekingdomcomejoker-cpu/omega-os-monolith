/**
 * 🔭 OMEGA TELEMETRY (PROMETHEUS)
 * Role: Sensory Input (The Nerve)
 * Function: Exports real-time metrics for Lambda_t calculation.
 */

export class TelemetryService {
  private successfulTasks: number = 0;
  private errorEvents: number = 0;

  public logSuccess(): void {
    this.successfulTasks++;
  }

  public logError(): void {
    this.errorEvents++;
  }

  /**
   * Calculate Lambda_t (Time-Bounded Coherence)
   * Formula: Successes / (Errors + 1)
   */
  public getLambda(): number {
    return this.successfulTasks / (this.errorEvents + 1);
  }

  /**
   * Get Prometheus Metrics Format
   */
  public getMetrics(): string {
    return `
# HELP omega_successful_tasks_total Total successful tasks
# TYPE omega_successful_tasks_total counter
omega_successful_tasks_total ${this.successfulTasks}

# HELP omega_error_events_total Total error events
# TYPE omega_error_events_total counter
omega_error_events_total ${this.errorEvents}

# HELP omega_lambda_index Smoothed Coherence Score
# TYPE omega_lambda_index gauge
omega_lambda_index ${this.getLambda().toFixed(3)}
    `.trim();
  }
}
