import type { MissionSnapshot } from "../types/mission";

/**
 * Defines the data contract required by the mission dashboard.
 *
 * Implementations may load mission data from local fixtures,
 * an HTTP API, or another integration adapter.
 */
export interface MissionDataSource {
  loadSnapshot(): Promise<MissionSnapshot>;
}