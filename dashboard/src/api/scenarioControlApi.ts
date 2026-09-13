export type ScenarioType =
  | "Ideal"
  | "DenseDebris"
  | "HighNoise"
  | "DeepBurial"
  | "MultipleVictims"
  | "WeakVitalSigns"
  | "Custom";

export type ScenarioRunRequest = {
  schemaVersion: "1.0";
  scenarioType: ScenarioType;
  randomSeed?: number;
  numVictims?: number;
  debrisDensity?: number;
  noiseLevel?: number;
  burialDepth?: number;
  vitalStrength?: number;
};

export type ScenarioRunStatus = {
  runId: string | null;
  status: "IDLE" | "STARTING_MATLAB" | "RUNNING" | "COMPLETED" | "FAILED" | string;
  message: string;
  processId: number | null;
  returnCode: number | null;
  missionId: string | null;
  request: ScenarioRunRequest | null;
  requestPath: string | null;
  logPath: string | null;
};

type SuccessEnvelope<T> = {
  success: true;
  data: T;
};

type ErrorEnvelope = {
  success: false;
  error?: {
    code?: string;
    message?: string;
  };
};

const baseUrl = (
  import.meta.env.VITE_USAR_API_BASE_URL ?? "/api/v1"
).replace(/\/+$/, "");

const browserFetch = globalThis.fetch.bind(globalThis);

export async function startScenario(
  request: ScenarioRunRequest,
): Promise<ScenarioRunStatus> {
  return requestJson<ScenarioRunStatus>("/scenario/run", {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(request),
  });
}

export async function getScenarioRunStatus(): Promise<ScenarioRunStatus> {
  return requestJson<ScenarioRunStatus>("/scenario/run/current", {
    method: "GET",
    headers: { Accept: "application/json" },
    cache: "no-store",
  });
}

async function requestJson<T>(
  path: string,
  init: RequestInit,
): Promise<T> {
  const response = await browserFetch(`${baseUrl}${path}`, init);
  const payload = (await response.json()) as SuccessEnvelope<T> | ErrorEnvelope;

  if (!response.ok || payload.success !== true) {
    const message =
      payload.success === false
        ? payload.error?.message
        : undefined;
    throw new Error(message ?? `Scenario API failed with HTTP ${response.status}.`);
  }

  return payload.data;
}
