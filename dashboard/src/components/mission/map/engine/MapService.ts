import type { GroundTruthVictim } from "../../../../types/groundTruth";
import type { Position } from "../../../../types/position";
import type {
  RescueRoute,
  RescueRouteMode,
  Victim,
} from "../../../../types/victim";

import { createMap } from "./createMap";
import {
  VictimSelectionInteraction,
  type VictimSelectHandler,
} from "./interactions/VictimSelectionInteraction";

type MapContext = ReturnType<typeof createMap>;

export class MapService {
  private readonly context: MapContext;
  private readonly victimSelectionInteraction: VictimSelectionInteraction;
  private selectedVictimId: number | null = null;

  constructor(target: HTMLDivElement, onSelectVictim: VictimSelectHandler) {
    this.context = createMap(target);
    this.victimSelectionInteraction = new VictimSelectionInteraction(
      this.context.map,
      this.context.layers.victims,
      onSelectVictim,
    );
  }

  setVictims(victims: Victim[]): void {
    this.context.layers.victims.setVictims(victims);
    this.applySelectedVictim();
  }

  setGroundTruth(victims: GroundTruthVictim[]): void {
    this.context.layers.groundTruth.setGroundTruth(victims);
  }

  setGroundTruthVisible(visible: boolean): void {
    this.context.layerManager.setVisible(
      this.context.layers.groundTruth.id,
      visible,
    );
  }

  setSelectedVictim(id: number | null): void {
    this.selectedVictimId = id;
    this.applySelectedVictim();
  }

  setProbe(position: Position | null, path: Position[]): void {
    this.context.layers.probe.setProbe(position, path);
  }

  setObstacles(obstacles: Position[]): void {
    this.context.layers.obstacles.setObstacles(obstacles);
  }

  setRescueRoute(
    route: RescueRoute | null,
    mode: RescueRouteMode,
  ): void {
    this.context.layers.rescueRoute.setRoute(route, mode);
  }

  updateSize(): void {
    this.context.map.updateSize();
  }

  destroy(): void {
    this.victimSelectionInteraction.dispose();
    this.context.layerManager.dispose();
    this.context.map.setTarget(undefined);
  }

  private applySelectedVictim(): void {
    this.context.layers.victims.setSelectedVictim(this.selectedVictimId);
    this.victimSelectionInteraction.setSelectedVictim(this.selectedVictimId);
  }
}
