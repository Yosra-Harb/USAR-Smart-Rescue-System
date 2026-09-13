import Feature from "ol/Feature";
import LineString from "ol/geom/LineString";
import VectorLayer from "ol/layer/Vector";
import VectorSource from "ol/source/Vector";
import Stroke from "ol/style/Stroke";
import Style from "ol/style/Style";

import { LAYER_ORDER } from "../../config/layerOrder";
import { GRID_SPACING } from "../constants/mapConstants";
import {
  SIMULATION_HEIGHT,
  SIMULATION_WIDTH,
} from "../projection/SimulationProjection";

import type { MapLayer } from "./MapLayer";

export class GridVectorLayer
  implements MapLayer<VectorLayer<VectorSource>>
{
  public readonly id = "grid";

  public readonly zIndex = LAYER_ORDER.GRID;

  private readonly source: VectorSource;

  private readonly layer: VectorLayer<VectorSource>;

  constructor() {
    this.source = new VectorSource();

    this.layer = new VectorLayer({
      source: this.source,

      style: new Style({
        stroke: new Stroke({
          color: "rgba(255,255,255,0.12)",
          width: 1,
        }),
      }),

      zIndex: this.zIndex,
    });

    this.createGrid();
  }

  public getLayer(): VectorLayer<VectorSource> {
    return this.layer;
  }

  public dispose(): void {
    this.source.clear();
  }

  private createGrid(): void {
    for (
      let x = 0;
      x <= SIMULATION_WIDTH;
      x += GRID_SPACING
    ) {
      this.source.addFeature(
        new Feature({
          geometry: new LineString([
            [x, 0],
            [x, SIMULATION_HEIGHT],
          ]),
        }),
      );
    }

    for (
      let y = 0;
      y <= SIMULATION_HEIGHT;
      y += GRID_SPACING
    ) {
      this.source.addFeature(
        new Feature({
          geometry: new LineString([
            [0, y],
            [SIMULATION_WIDTH, y],
          ]),
        }),
      );
    }
  }
}