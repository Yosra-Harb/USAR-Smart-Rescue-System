import Feature from "ol/Feature";
import LineString from "ol/geom/LineString";
import Point from "ol/geom/Point";
import VectorLayer from "ol/layer/Vector";
import VectorSource from "ol/source/Vector";
import CircleStyle from "ol/style/Circle";
import Fill from "ol/style/Fill";
import Stroke from "ol/style/Stroke";
import Style from "ol/style/Style";

import type { Position } from "../../../../../types/position";
import { LAYER_ORDER } from "../../config/layerOrder";
import type { MapLayer } from "./MapLayer";

export class ProbeMapLayer implements MapLayer<VectorLayer<VectorSource>> {
  public readonly id = "probe";
  public readonly zIndex = LAYER_ORDER.ROBOTS;

  private readonly source = new VectorSource();
  private readonly layer = new VectorLayer({
    source: this.source,
    zIndex: this.zIndex,
  });

  public getLayer(): VectorLayer<VectorSource> {
    return this.layer;
  }

  public setProbe(position: Position | null, path: Position[]): void {
    this.source.clear();

    if (path.length >= 2) {
      const pathFeature = new Feature({
        geometry: new LineString(path.map((point) => [point.x, point.y])),
      });
      pathFeature.setStyle(
        new Style({
          stroke: new Stroke({
            color: "rgba(34, 211, 238, 0.34)",
            width: 1.5,
          }),
        }),
      );
      this.source.addFeature(pathFeature);
    }

    if (position) {
      const pointFeature = new Feature({
        geometry: new Point([position.x, position.y]),
      });
      pointFeature.setStyle(
        new Style({
          image: new CircleStyle({
            radius: 8,
            fill: new Fill({ color: "#22d3ee" }),
            stroke: new Stroke({ color: "#ecfeff", width: 3 }),
          }),
        }),
      );
      this.source.addFeature(pointFeature);
    }
  }

  public dispose(): void {
    this.source.clear();
  }
}
