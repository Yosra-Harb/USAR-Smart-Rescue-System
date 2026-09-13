import Feature from "ol/Feature";
import LineString from "ol/geom/LineString";
import Point from "ol/geom/Point";
import VectorLayer from "ol/layer/Vector";
import VectorSource from "ol/source/Vector";
import CircleStyle from "ol/style/Circle";
import Fill from "ol/style/Fill";
import Stroke from "ol/style/Stroke";
import Style from "ol/style/Style";
import Text from "ol/style/Text";

import type {
  RescueRoute,
  RescueRouteMode,
} from "../../../../../types/victim";
import { LAYER_ORDER } from "../../config/layerOrder";
import type { MapLayer } from "./MapLayer";

export class RescueRouteLayer implements MapLayer<VectorLayer<VectorSource>> {
  public readonly id = "rescue-route";
  public readonly zIndex = LAYER_ORDER.RESCUE_ROUTE;

  private readonly source = new VectorSource();
  private readonly layer = new VectorLayer({
    source: this.source,
    zIndex: this.zIndex,
  });

  public getLayer(): VectorLayer<VectorSource> {
    return this.layer;
  }

  public setRoute(route: RescueRoute | null, mode: RescueRouteMode): void {
    this.source.clear();

    if (!route || !route.reachable || route.path.length === 0) {
      return;
    }

    const color = mode === "recommended" ? "#c084fc" : "#f59e0b";
    const softColor = mode === "recommended"
      ? "rgba(192, 132, 252, 0.30)"
      : "rgba(245, 158, 11, 0.25)";

    if (route.path.length >= 2) {
      const glow = new Feature({
        geometry: new LineString(route.path.map((point) => [point.x, point.y])),
      });
      glow.setStyle(new Style({
        stroke: new Stroke({
          color: softColor,
          width: 10,
        }),
      }));
      this.source.addFeature(glow);

      const line = new Feature({
        geometry: new LineString(route.path.map((point) => [point.x, point.y])),
      });
      line.setStyle(new Style({
        stroke: new Stroke({
          color,
          width: 4,
          lineDash: mode === "shortest" ? [9, 7] : undefined,
        }),
      }));
      this.source.addFeature(line);
    }

    route.path.forEach((point, index) => {
      const isEndpoint = index === 0 || index === route.path.length - 1;
      if (!isEndpoint && index % 2 !== 0) {
        return;
      }

      const node = new Feature({
        geometry: new Point([point.x, point.y]),
      });
      node.setStyle(new Style({
        image: new CircleStyle({
          radius: isEndpoint ? 5 : 2.5,
          fill: new Fill({ color: isEndpoint ? color : "#e2e8f0" }),
          stroke: new Stroke({ color: "#020617", width: isEndpoint ? 2 : 1 }),
        }),
      }));
      this.source.addFeature(node);
    });

    const start = route.path[0];
    const startFeature = new Feature({
      geometry: new Point([start.x, start.y]),
    });
    startFeature.setStyle(new Style({
      image: new CircleStyle({
        radius: 8,
        fill: new Fill({ color: "#22c55e" }),
        stroke: new Stroke({ color: "#dcfce7", width: 2.5 }),
      }),
      text: new Text({
        text: "START",
        offsetY: -18,
        font: "700 10px sans-serif",
        fill: new Fill({ color: "#dcfce7" }),
        stroke: new Stroke({ color: "#020617", width: 3 }),
      }),
    }));
    this.source.addFeature(startFeature);

    const access = route.accessPoint ?? route.path[route.path.length - 1];
    const accessFeature = new Feature({
      geometry: new Point([access.x, access.y]),
    });
    accessFeature.setStyle(new Style({
      image: new CircleStyle({
        radius: 8,
        fill: new Fill({ color }),
        stroke: new Stroke({ color: "#f8fafc", width: 2.5 }),
      }),
      text: new Text({
        text: "ACCESS",
        offsetX: 45,
        offsetY: 0,
        font: "700 10px sans-serif",
        fill: new Fill({ color: "#f8fafc" }),
        stroke: new Stroke({ color: "#020617", width: 3 }),
      }),
    }));
    this.source.addFeature(accessFeature);
  }

  public dispose(): void {
    this.source.clear();
  }
}
