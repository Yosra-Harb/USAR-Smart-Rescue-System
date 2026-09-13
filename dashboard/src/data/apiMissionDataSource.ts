import type {
  MissionEvaluation,
  MissionScenarioSummary,
  MissionSnapshot,
  OperationalMapData,
  ProbeState,
} from "../types/mission";
import type {
  MissionFusion,
  MissionSensorReading,
  MissionSensors,
} from "../types/fusion";
import type { GroundTruthVictim } from "../types/groundTruth";
import type { MissionEvent } from "../types/missionEvent";
import type { Position } from "../types/position";
import type {
  RescueRoute,
  RescueRouteMode,
  Victim,
  VictimPriority,
} from "../types/victim";

import type { MissionDataSource } from "./missionDataSource";

type FetchFunction = typeof fetch;
type UnknownRecord = Record<string, unknown>;

export type ApiMissionDataSourceOptions = {
  baseUrl: string;
  requestTimeoutMs?: number;
  fetcher?: FetchFunction;
};

export class MissionApiError extends Error {
  public readonly status: number | null;

  constructor(
    message: string,
    status: number | null = null,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = "MissionApiError";
    this.status = status;
  }
}

export class ApiMissionDataSource implements MissionDataSource {
  private readonly baseUrl: string;
  private readonly requestTimeoutMs: number;
  private readonly fetcher: FetchFunction;

  private missionId: string | null = null;
  private lastFetchedSequence = -1;
  private readonly telemetryBySequence = new Map<number, UnknownRecord>();

  constructor(options: ApiMissionDataSourceOptions) {
    this.baseUrl = options.baseUrl.replace(/\/+$/, "");
    this.requestTimeoutMs = options.requestTimeoutMs ?? 10_000;
    // Bind the browser-native fetch to globalThis.
    // Calling a Web API method through an arbitrary object property can
    // trigger an "Illegal invocation" TypeError in some browser runtimes.
    // Keeping an explicitly bound function makes the data source portable
    // across Chrome/Edge and test environments.
    this.fetcher = options.fetcher ?? globalThis.fetch.bind(globalThis);

    if (!this.baseUrl) {
      throw new Error("ApiMissionDataSource requires a base URL.");
    }
  }

  async loadSnapshot(): Promise<MissionSnapshot> {
    const state = await this.getData("/mission/current/state");
    const missionId = readString(state.missionId, "UNKNOWN_MISSION");

    if (missionId !== this.missionId) {
      this.missionId = missionId;
      this.lastFetchedSequence = -1;
      this.telemetryBySequence.clear();
    }

    await this.loadNewTelemetry();

    const status = readString(state.status, "UNKNOWN");
    const completed = status === "COMPLETED";

    const result = completed
      ? await this.tryGetData("/mission/current/result")
      : null;

    const evaluation = completed
      ? await this.tryGetData("/mission/current/evaluation")
      : null;

    const victims = result
      ? mapFinalVictims(result, state)
      : mapProvisionalTracks(state);

    const telemetry = [...this.telemetryBySequence.values()].sort(
      (first, second) =>
        readNumber(first.sequence, -1) - readNumber(second.sequence, -1),
    );

    const fusion = mapFusion(state.fusion);
    const probe = mapProbe(state.probe);
    const sensors = mapSensors(state.sensors);
    const groundTruth = evaluation
      ? mapGroundTruth(evaluation)
      : undefined;

    return {
      missionId,
      runId: missionId,
      status: {
        missionStatus: status,
        elapsedTime: formatElapsed(readNumber(state.elapsedSeconds, 0)),
        detectedVictims: completed
          ? victims.length
          : readNumber(state.activeTrackCount, victims.length),
        fusionStatus: fusion?.score === null || fusion === null
          ? "Waiting"
          : `Score ${formatPercent(fusion.score)}`,
        communicationStatus: "Connected",
        lastSequence: readNumber(state.lastSequence, -1),
      },
      victims,
      ...(groundTruth ? { groundTruth } : {}),
      events: mapTimeline(telemetry, state),
      probe,
      probePath: mapProbePath(telemetry),
      sensors,
      fusion,
      decision: nullableString(state.decision),
      activeTrackCount: readNumber(state.activeTrackCount, 0),
      scenario: mapScenario(state.scenario),
      operationalMap: result ? mapOperationalMap(result.operationalMap) : null,
      evaluation: evaluation ? mapEvaluation(evaluation) : null,
    };
  }

  private async loadNewTelemetry(): Promise<void> {
    let hasMore = true;

    while (hasMore) {
      const page = await this.getData(
        `/mission/current/telemetry?after_sequence=${this.lastFetchedSequence}&limit=500`,
      );

      const events = normalizeArray(page.events);

      for (const value of events) {
        const event = asRecord(value);
        if (!event) {
          continue;
        }

        const sequence = readNumber(event.sequence, -1);
        if (sequence >= 0) {
          this.telemetryBySequence.set(sequence, event);
          this.lastFetchedSequence = Math.max(
            this.lastFetchedSequence,
            sequence,
          );
        }
      }

      hasMore = page.hasMore === true && events.length > 0;
    }
  }

  private async tryGetData(path: string): Promise<UnknownRecord | null> {
    try {
      return await this.getData(path);
    } catch (error: unknown) {
      if (
        error instanceof MissionApiError &&
        (error.status === 404 || error.status === 409)
      ) {
        return null;
      }
      throw error;
    }
  }

  private async getData(path: string): Promise<UnknownRecord> {
    const controller = new AbortController();
    const timeoutId = globalThis.setTimeout(
      () => controller.abort(),
      this.requestTimeoutMs,
    );

    try {
      const response = await this.fetcher(`${this.baseUrl}${path}`, {
        method: "GET",
        headers: { Accept: "application/json" },
        cache: "no-store",
        signal: controller.signal,
      });

      let payload: unknown;
      try {
        payload = await response.json();
      } catch (error: unknown) {
        throw new MissionApiError(
          "Backend returned invalid JSON.",
          response.status,
          { cause: error },
        );
      }

      const envelope = asRecord(payload);
      if (!response.ok || envelope?.success !== true) {
        const errorObject = asRecord(envelope?.error);
        throw new MissionApiError(
          readString(errorObject?.message, `Backend request failed with HTTP ${response.status}.`),
          response.status,
        );
      }

      const data = asRecord(envelope.data);
      if (!data) {
        throw new MissionApiError(
          "Backend success envelope did not contain an object in data.",
          response.status,
        );
      }

      return data;
    } catch (error: unknown) {
      if (error instanceof MissionApiError) {
        throw error;
      }

      if (controller.signal.aborted) {
        throw new MissionApiError("Backend request timed out.", null, {
          cause: error,
        });
      }

      const detail =
        error instanceof Error && error.message
          ? ` (${error.name}: ${error.message})`
          : "";

      throw new MissionApiError(
        "Unable to reach the USAR backend at " +
          this.baseUrl +
          detail,
        null,
        { cause: error },
      );
    } finally {
      globalThis.clearTimeout(timeoutId);
    }
  }
}

function mapProbe(value: unknown): ProbeState | null {
  const probe = asRecord(value);
  if (!probe) {
    return null;
  }

  return {
    id: nullableNumber(probe.id),
    position: mapPoint(probe.position),
    state: readString(probe.state, "UNKNOWN"),
    currentStep: nullableNumber(probe.currentStep),
    coverage: nullableNumber(probe.coverage),
  };
}

function mapSensors(value: unknown): MissionSensors | null {
  const sensors = asRecord(value);
  if (!sensors) {
    return null;
  }

  return {
    quality: nullableNumber(sensors.quality),
    radar: mapSensor(sensors.radar),
    thermal: mapSensor(sensors.thermal),
    acoustic: mapSensor(sensors.acoustic),
  };
}

function mapSensor(value: unknown): MissionSensorReading {
  const sensor = asRecord(value);
  return {
    normalized: nullableNumber(sensor?.normalized),
    physical: nullableNumber(sensor?.physical),
    unit: readString(sensor?.unit, ""),
    reliability: nullableNumber(sensor?.reliability),
  };
}

function mapFusion(value: unknown): MissionFusion | null {
  const fusion = asRecord(value);
  if (!fusion) {
    return null;
  }

  const weights = asRecord(fusion.weights);
  return {
    score: nullableNumber(fusion.score),
    confidence: nullableNumber(fusion.confidence),
    weights: {
      radar: nullableNumber(weights?.radar),
      thermal: nullableNumber(weights?.thermal),
      acoustic: nullableNumber(weights?.acoustic),
    },
  };
}

function mapScenario(value: unknown): MissionScenarioSummary | null {
  const scenario = asRecord(value);
  if (!scenario) {
    return null;
  }

  return {
    scenarioType: readString(scenario.scenarioType, "Unknown"),
    randomSeed: nullableNumber(scenario.randomSeed),
    gridSize: normalizeArray(scenario.gridSize)
      .map((item) => nullableNumber(item))
      .filter((item): item is number => item !== null),
    numVictims: nullableNumber(scenario.numVictims),
    debrisDensity: nullableNumber(scenario.debrisDensity),
    noiseLevel: nullableNumber(scenario.noiseLevel),
    burialDepth: nullableNumber(scenario.burialDepth),
    vitalStrength: nullableNumber(scenario.vitalStrength),
  };
}

function mapProvisionalTracks(state: UnknownRecord): Victim[] {
  const latest = readString(state.latestTimestampUtc, "Live");

  return normalizeArray(state.tracks)
    .map((value): Victim | null => {
      const track = asRecord(value);
      if (!track) {
        return null;
      }

      const id = readNumber(track.id, -1);
      const position = mapPoint(track.estimatedPosition);
      if (id <= 0 || !position) {
        return null;
      }

      return {
        id,
        position,
        status: "PROVISIONAL TRACK",
        priority: mapPriority(track.priorityLevel),
        confidence: null,
        vitalityIndex: nullableNumber(track.vitalityIndex),
        medicalSeverity: nullableNumber(track.medicalSeverity),
        priorityScore: nullableNumber(track.priorityScore),
        rescueRank: nullableNumber(track.rescueRank),
        reachable: null,
        independentViewCount: null,
        provisional: true,
        shortestRoute: null,
        recommendedRoute: null,
        lastUpdate: latest,
      } satisfies Victim;
    })
    .filter((victim): victim is Victim => victim !== null)
    .sort(sortVictims);
}

function mapFinalVictims(result: UnknownRecord, state: UnknownRecord): Victim[] {
  const latest = readString(state.latestTimestampUtc, "Final");

  return normalizeArray(result.victims)
    .map((value): Victim | null => {
      const item = asRecord(value);
      if (!item) {
        return null;
      }

      const id = readNumber(item.id, -1);
      const position = mapPoint(item.estimatedPosition);
      if (id <= 0 || !position) {
        return null;
      }

      return {
        id,
        position,
        status: readString(item.condition, "CONFIRMED"),
        priority: mapPriority(item.priorityLevel),
        confidence: null,
        vitalityIndex: nullableNumber(item.vitalityIndex),
        medicalSeverity: nullableNumber(item.medicalSeverity),
        priorityScore: nullableNumber(item.priorityScore),
        rescueRank: nullableNumber(item.rescueRank),
        reachable: typeof item.reachable === "boolean" ? item.reachable : null,
        independentViewCount: nullableNumber(item.independentViewCount),
        provisional: false,
        shortestRoute: mapRoute(item.shortestRoute, "shortest"),
        recommendedRoute: mapRoute(item.recommendedRoute, "recommended"),
        lastUpdate: latest,
      } satisfies Victim;
    })
    .filter((victim): victim is Victim => victim !== null)
    .sort(sortVictims);
}

function mapRoute(
  value: unknown,
  fallbackMode: RescueRouteMode,
): RescueRoute | null {
  const route = asRecord(value);
  if (!route) {
    return null;
  }

  const path = mapPath(route.path);
  const reachable =
    typeof route.reachable === "boolean"
      ? route.reachable
      : path.length > 0;

  return {
    mode: mapRouteMode(route.mode, fallbackMode),
    reachable,
    path,
    pathLength: nullableNumber(route.pathLength),
    travelCost: nullableNumber(route.travelCost),
    meanRisk: nullableNumber(route.meanRisk),
    maximumRisk: nullableNumber(route.maximumRisk),
    meanAccessibility: nullableNumber(route.meanAccessibility),
    meanDebris: nullableNumber(route.meanDebris),
    expandedNodes: nullableNumber(route.expandedNodes),
    accessPoint: mapPoint(route.accessPoint),
  };
}

function mapRouteMode(
  value: unknown,
  fallback: RescueRouteMode,
): RescueRouteMode {
  const mode = readString(value, fallback).toLowerCase();
  return mode === "shortest" ? "shortest" : "recommended";
}

function mapOperationalMap(value: unknown): OperationalMapData | null {
  const map = asRecord(value);
  if (!map) {
    return null;
  }

  return {
    gridSize: normalizeArray(map.gridSize)
      .map((item) => nullableNumber(item))
      .filter((item): item is number => item !== null),
    entryPoint: mapPoint(map.entryPoint),
    exitPoint: mapPoint(map.exitPoint),
    obstacles: mapPath(map.obstacles),
    obstacleCount: readNumber(map.obstacleCount, 0),
  };
}

function mapEvaluation(value: UnknownRecord): MissionEvaluation {
  const counts = asRecord(value.counts);
  const detection = asRecord(value.detection);
  const localization = asRecord(value.localization);

  return {
    precision: nullableNumber(detection?.precision),
    recall: nullableNumber(detection?.recall),
    f1Score: nullableNumber(detection?.f1Score),
    criticalSuccessIndex: nullableNumber(detection?.criticalSuccessIndex),
    truePositives: nullableNumber(counts?.truePositives),
    falsePositives: nullableNumber(counts?.falsePositives),
    falseNegatives: nullableNumber(counts?.falseNegatives),
    localizationMeanError: nullableNumber(localization?.meanError),
    localizationRmse: nullableNumber(localization?.rmse),
    localizationMaxError: nullableNumber(localization?.maximumError),
  };
}

function mapGroundTruth(value: UnknownRecord): GroundTruthVictim[] {
  const positions = asRecord(value.positions);
  return mapPath(positions?.groundTruth).map((position, index) => ({
    id: index + 1,
    position,
  }));
}

function mapProbePath(records: UnknownRecord[]): Position[] {
  const path: Position[] = [];
  let previous: Position | null = null;

  for (const record of records) {
    const probe = asRecord(record.probe);
    const position = mapPoint(probe?.position);
    if (!position) {
      continue;
    }

    if (
      previous &&
      previous.x === position.x &&
      previous.y === position.y
    ) {
      continue;
    }

    path.push(position);
    previous = position;
  }

  return path;
}

function mapTimeline(records: UnknownRecord[], state: UnknownRecord): MissionEvent[] {
  const startedAt = parseTimestamp(readString(state.startedAtUtc, ""));
  const output: MissionEvent[] = [];
  let lastDecision = "";

  for (const record of records) {
    const sequence = readNumber(record.sequence, -1);
    const eventType = readString(record.eventType, "UNKNOWN");
    const elapsedSeconds = elapsedFrom(startedAt, record.timestampUtc);

    if (eventType === "MISSION_STARTED") {
      output.push({
        id: `telemetry-${sequence}`,
        elapsedSeconds,
        category: "MISSION",
        title: "Mission started",
        description: "MATLAB telemetry stream started and the backend connected to the mission.",
      });
      continue;
    }

    if (eventType === "VICTIM_TRACK_CREATED") {
      const newTracks = normalizeArray(record.newTracks);
      for (const value of newTracks) {
        const track = asRecord(value);
        const id = readNumber(track?.id, -1);
        if (id <= 0) {
          continue;
        }
        output.push({
          id: `telemetry-${sequence}-track-${id}`,
          elapsedSeconds,
          category: "DETECTION",
          title: `Track #${id} created`,
          description: "A provisional victim track was created from live MATLAB inference.",
          victimId: id,
        });
      }
    }

    const decision = readString(record.decision, "");
    if (
      decision &&
      decision !== "UNKNOWN" &&
      decision !== "RESUME_SEARCH" &&
      decision !== lastDecision
    ) {
      output.push({
        id: `telemetry-${sequence}-decision`,
        elapsedSeconds,
        category: "DECISION",
        title: decision.replaceAll("_", " "),
        description: "Mission controller changed its operational decision.",
      });
    }
    if (decision) {
      lastDecision = decision;
    }

    if (eventType === "MISSION_COMPLETED") {
      output.push({
        id: `telemetry-${sequence}`,
        elapsedSeconds,
        category: "MISSION",
        title: "Mission completed",
        description: "Final result and post-mission evaluation are now available.",
      });
    }
  }

  return output.slice(-200);
}

function mapPath(value: unknown): Position[] {
  if (Array.isArray(value)) {
    const flatX = nullableNumber(value[0]);
    const flatY = nullableNumber(value[1]);

    if (value.length >= 2 && flatX !== null && flatY !== null) {
      return [{ x: flatX, y: flatY }];
    }
  }

  const items = normalizeArray(value);
  const output: Position[] = [];

  for (const item of items) {
    if (Array.isArray(item) && item.length >= 2) {
      const x = nullableNumber(item[0]);
      const y = nullableNumber(item[1]);
      if (x !== null && y !== null) {
        output.push({ x, y });
      }
      continue;
    }

    const point = mapPoint(item);
    if (point) {
      output.push(point);
    }
  }

  return output;
}

function mapPoint(value: unknown): Position | null {
  const point = asRecord(value);
  if (!point) {
    return null;
  }

  const x = nullableNumber(point.x);
  const y = nullableNumber(point.y);

  return x === null || y === null ? null : { x, y };
}

function mapPriority(value: unknown): VictimPriority {
  const priority = readString(value, "UNKNOWN").toUpperCase();
  if (priority === "LOW" || priority === "MEDIUM" || priority === "HIGH") {
    return priority;
  }
  return "UNKNOWN";
}

function sortVictims(first: Victim, second: Victim): number {
  // Live ranks can be duplicated before route planning. Order provisional
  // tracks by their current score without presenting it as a final rescue rank.
  if (first.provisional && second.provisional) {
    const firstScore = first.priorityScore ?? -1;
    const secondScore = second.priorityScore ?? -1;
    return secondScore - firstScore || first.id - second.id;
  }

  if (first.provisional !== second.provisional) {
    return first.provisional ? 1 : -1;
  }

  // Final rank is computed in MATLAB after evaluating actual rescue routes.
  const firstRank = first.rescueRank ?? Number.MAX_SAFE_INTEGER;
  const secondRank = second.rescueRank ?? Number.MAX_SAFE_INTEGER;
  return firstRank - secondRank ||
    (second.priorityScore ?? -1) - (first.priorityScore ?? -1) ||
    first.id - second.id;
}

function normalizeArray(value: unknown): unknown[] {
  if (Array.isArray(value)) {
    return value;
  }
  return value === undefined || value === null ? [] : [value];
}

function asRecord(value: unknown): UnknownRecord | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as UnknownRecord)
    : null;
}

function nullableNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function readNumber(value: unknown, fallback: number): number {
  return nullableNumber(value) ?? fallback;
}

function nullableString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value : null;
}

function readString(value: unknown, fallback: string): string {
  return nullableString(value) ?? fallback;
}

function formatElapsed(totalSeconds: number): string {
  const seconds = Math.max(0, Math.floor(totalSeconds));
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainder = seconds % 60;
  return [hours, minutes, remainder]
    .map((part) => String(part).padStart(2, "0"))
    .join(":");
}

function formatPercent(value: number): string {
  return `${Math.round(value * 100)}%`;
}

function parseTimestamp(value: string): number | null {
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function elapsedFrom(startedAt: number | null, timestamp: unknown): number {
  if (startedAt === null || typeof timestamp !== "string") {
    return 0;
  }
  const current = Date.parse(timestamp);
  return Number.isFinite(current)
    ? Math.max(0, (current - startedAt) / 1000)
    : 0;
}
