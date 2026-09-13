import Map from "ol/Map";

import { createView } from "./createView";
import { GroundTruthLayer } from "./layers/GroundTruthLayer";
import { GridVectorLayer } from "./layers/GridVectorLayer";
import { LayerManager } from "./layers/LayerManager";
import { ObstacleMapLayer } from "./layers/ObstacleMapLayer";
import { ProbeMapLayer } from "./layers/ProbeMapLayer";
import { RescueRouteLayer } from "./layers/RescueRouteLayer";
import { VictimMapLayer } from "./layers/VictimMapLayer";
import { SIMULATION_EXTENT } from "./projection/SimulationProjection";

export function createMap(target: HTMLDivElement) {
  const layers = {
    grid: new GridVectorLayer(),
    obstacles: new ObstacleMapLayer(),
    groundTruth: new GroundTruthLayer(),
    rescueRoute: new RescueRouteLayer(),
    victims: new VictimMapLayer(),
    probe: new ProbeMapLayer(),
  } as const;

  const map = new Map({
    target,
    view: createView(),
    controls: [],
    interactions: [],
  });

  const layerManager = new LayerManager(map);
  layerManager.register(layers.grid);
  layerManager.register(layers.obstacles);
  layerManager.register(layers.groundTruth);
  layerManager.register(layers.rescueRoute);
  layerManager.register(layers.victims);
  layerManager.register(layers.probe);

  map.getView().fit(SIMULATION_EXTENT, {
    padding: [28, 28, 28, 28],
    duration: 0,
  });

  return { map, layerManager, layers };
}
