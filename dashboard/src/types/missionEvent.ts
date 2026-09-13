export const MISSION_EVENT_CATEGORIES = [
  "MISSION",
  "DETECTION",
  "ASSESSMENT",
  "DECISION",
  "SYSTEM",
] as const;

export type MissionEventCategory =
  (typeof MISSION_EVENT_CATEGORIES)[number];

export interface MissionEvent {
  id: string;
  elapsedSeconds: number;
  category: MissionEventCategory;
  title: string;
  description: string;
  victimId?: number;
}
