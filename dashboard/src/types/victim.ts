import type { Position } from "./position";

export type VictimPriority =
  | "LOW"
  | "MEDIUM"
  | "HIGH"
  | "UNKNOWN";

export type RescueRouteMode = "recommended" | "shortest";

export interface RescueRoute {
  mode: RescueRouteMode;
  reachable: boolean;
  path: Position[];
  pathLength: number | null;
  travelCost: number | null;
  meanRisk: number | null;
  maximumRisk: number | null;
  meanAccessibility: number | null;
  meanDebris: number | null;
  expandedNodes: number | null;
  accessPoint: Position | null;
}

export interface Victim {
  id: number;
  position: Position;
  status: string;
  priority: VictimPriority;
  confidence: number | null;
  vitalityIndex: number | null;
  medicalSeverity: number | null;
  priorityScore: number | null;
  rescueRank: number | null;
  reachable: boolean | null;
  independentViewCount: number | null;
  provisional: boolean;
  shortestRoute: RescueRoute | null;
  recommendedRoute: RescueRoute | null;
  lastUpdate: string;
}
