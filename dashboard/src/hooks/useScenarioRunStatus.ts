import { useEffect, useState } from "react";

import {
  getScenarioRunStatus,
  type ScenarioRunStatus,
} from "../api/scenarioControlApi";

export function useScenarioRunStatus(
  pollingIntervalMs = 1000,
): ScenarioRunStatus | null {
  const [status, setStatus] = useState<ScenarioRunStatus | null>(null);

  useEffect(() => {
    let cancelled = false;
    let timer: number | undefined;

    async function poll(): Promise<void> {
      try {
        const next = await getScenarioRunStatus();
        if (!cancelled) {
          setStatus(next);
        }
      } catch {
        // Mission telemetry has its own connection error state. The launcher
        // status is supplemental and must not blank the operational screen.
      } finally {
        if (!cancelled) {
          timer = window.setTimeout(() => void poll(), pollingIntervalMs);
        }
      }
    }

    void poll();

    return () => {
      cancelled = true;
      if (timer !== undefined) {
        window.clearTimeout(timer);
      }
    };
  }, [pollingIntervalMs]);

  return status;
}
