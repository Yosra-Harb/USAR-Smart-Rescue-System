import Feature from "ol/Feature";
import Point from "ol/geom/Point";
import VectorLayer from "ol/layer/Vector";
import VectorSource from "ol/source/Vector";
import CircleStyle from "ol/style/Circle";
import Fill from "ol/style/Fill";
import Stroke from "ol/style/Stroke";
import Style from "ol/style/Style";
import Text from "ol/style/Text";

import type { GroundTruthVictim } from "../../../../../types/groundTruth";
import { LAYER_ORDER } from "../../config/layerOrder";
import type { MapLayer } from "./MapLayer";

export class GroundTruthLayer implements MapLayer<VectorLayer<VectorSource<Feature<Point>>>> {
  public readonly id = "ground-truth";
  public readonly zIndex = LAYER_ORDER.GROUND_TRUTH;
  private readonly source = new VectorSource<Feature<Point>>();
  private readonly layer = new VectorLayer({
    source: this.source,
    visible: false,
    zIndex: this.zIndex,
  });

  public getLayer(): VectorLayer<VectorSource<Feature<Point>>> {
    return this.layer;
  }

  public setGroundTruth(victims: GroundTruthVictim[]): void {
    this.source.clear();
    this.source.addFeatures(victims.map((victim) => this.createFeature(victim)));
  }

  public clear(): void {
    this.source.clear();
  }

  public dispose(): void {
    this.clear();
  }

  private createFeature(victim: GroundTruthVictim): Feature<Point> {
    const feature = new Feature<Point>({
      geometry: new Point([victim.position.x, victim.position.y]),
    });
    feature.setId(`ground-truth:${victim.id}`);
    feature.setStyle(
      new Style({
        image: new CircleStyle({
          radius: 24,
          stroke: new Stroke({ color: "#e9d5ff", width: 3, lineDash: [6, 4] }),
        }),
        text: new Text({
          text: `TRUTH #${victim.id}  (${victim.position.x.toFixed(1)}, ${victim.position.y.toFixed(1)})`,
          offsetY: 48,
          font: "700 11px sans-serif",
          fill: new Fill({ color: "#f3e8ff" }),
          backgroundFill: new Fill({ color: "rgba(5, 9, 20, 0.92)" }),
          backgroundStroke: new Stroke({ color: "#c084fc", width: 1.5 }),
          padding: [4, 6, 4, 6],
        }),
      }),
    );
    return feature;
  }
}
