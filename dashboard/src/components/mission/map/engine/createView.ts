import View from "ol/View";

import {
  SIMULATION_CENTER,
  SIMULATION_EXTENT,
  SIMULATION_PROJECTION,
} from "./projection/SimulationProjection";

export function createView(): View {
  return new View({
    projection: SIMULATION_PROJECTION,
    center: [...SIMULATION_CENTER],
    extent: SIMULATION_EXTENT,
    zoom: 0,
    showFullExtent: true,
  });
}
