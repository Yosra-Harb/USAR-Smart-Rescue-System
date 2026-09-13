import { ApiMissionDataSource } from "../data/apiMissionDataSource";
import type { MissionDataSource } from "../data/missionDataSource";

function createMissionDataSource(): MissionDataSource {
  const baseUrl = (
    import.meta.env.VITE_USAR_API_BASE_URL ??
    "/api/v1"
  ).trim();

  return new ApiMissionDataSource({ baseUrl });
}

export const missionDataSource = createMissionDataSource();
