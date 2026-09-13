import type { Extent } from "ol/extent";
import Projection from "ol/proj/Projection";

export const SIMULATION_PROJECTION_CODE = "USAR:SIMULATION";
export const SIMULATION_WIDTH = 50;
export const SIMULATION_HEIGHT = 50;
export const SIMULATION_EXTENT = [0, 0, SIMULATION_WIDTH, SIMULATION_HEIGHT] satisfies Extent;
export const SIMULATION_CENTER = [SIMULATION_WIDTH / 2, SIMULATION_HEIGHT / 2] as const;
export const SIMULATION_PROJECTION = new Projection({
  code: SIMULATION_PROJECTION_CODE,
  units: "m",
  extent: SIMULATION_EXTENT,
});
