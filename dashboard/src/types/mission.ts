import type { MissionSensors, MissionFusion } from "./fusion";
import type { GroundTruthVictim } from "./groundTruth";
import type { MissionEvent } from "./missionEvent";
import type { Position } from "./position";
import type { Victim } from "./victim";

export interface MissionStatus {
  missionStatus: string;
  elapsedTime: string;
  detectedVictims: number;
  fusionStatus: string;
  communicationStatus: string;
  lastSequence: number;
}

export interface ProbeState {
  id: number | null;
  position: Position | null;
  state: string;
  currentStep: number | null;
  coverage: number | null;
}

export interface MissionScenarioSummary {
  scenarioType: string;
  randomSeed: number | null;
  gridSize: number[];
  numVictims: number | null;
  debrisDensity: number | null;
  noiseLevel: number | null;
  burialDepth: number | null;
  vitalStrength: number | null;
}

export interface OperationalMapData {
  gridSize: number[];
  entryPoint: Position | null;
  exitPoint: Position | null;
  obstacles: Position[];
  obstacleCount: number;
}

export interface MissionEvaluation {
  precision: number | null;
  recall: number | null;
  f1Score: number | null;
  criticalSuccessIndex: number | null;
  truePositives: number | null;
  falsePositives: number | null;
  falseNegatives: number | null;
  localizationMeanError: number | null;
  localizationRmse: number | null;
  localizationMaxError: number | null;
}

export interface MissionSnapshot {
  missionId: string;
  runId: string;
  status: MissionStatus;
  victims: Victim[];
  groundTruth?: GroundTruthVictim[];
  events: MissionEvent[];
  probe: ProbeState | null;
  probePath: Position[];
  sensors: MissionSensors | null;
  fusion: MissionFusion | null;
  decision: string | null;
  activeTrackCount: number;
  scenario: MissionScenarioSummary | null;
  operationalMap: OperationalMapData | null;
  evaluation: MissionEvaluation | null;
}
