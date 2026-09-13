import Feature from "ol/Feature";
import Polygon from "ol/geom/Polygon";
import VectorLayer from "ol/layer/Vector";
import VectorSource from "ol/source/Vector";
import Fill from "ol/style/Fill";
import Stroke from "ol/style/Stroke";
import Style from "ol/style/Style";

import type { Position } from "../../../../../types/position";
import { LAYER_ORDER } from "../../config/layerOrder";
import type { MapLayer } from "./MapLayer";

export class ObstacleMapLayer implements MapLayer<VectorLayer<VectorSource>> {
  public readonly id = "obstacles";
  public readonly zIndex = LAYER_ORDER.OBSTACLES;

  private readonly source = new VectorSource();
  private readonly layer = new VectorLayer({
    source: this.source,
    zIndex: this.zIndex,
  });

  private readonly style = new Style({
    fill: new Fill({ color: "rgba(71, 85, 105, 0.68)" }),
    stroke: new Stroke({ color: "rgba(148, 163, 184, 0.42)", width: 0.7 }),
  });

  public getLayer(): VectorLayer<VectorSource> {
    return this.layer;
  }

  public setObstacles(obstacles: Position[]): void {
    this.source.clear();

    const features = obstacles.map((cell) => {
      const half = 0.46;
      const feature = new Feature({
        geometry: new Polygon([[
          [cell.x - half, cell.y - half],
          [cell.x + half, cell.y - half],
          [cell.x + half, cell.y + half],
          [cell.x - half, cell.y + half],
          [cell.x - half, cell.y - half],
        ]]),
      });
      feature.setStyle(this.style);
      feature.set("featureType", "obstacle");
      return feature;
    });

    this.source.addFeatures(features);
  }

  public dispose(): void {
    this.source.clear();
  }
}
