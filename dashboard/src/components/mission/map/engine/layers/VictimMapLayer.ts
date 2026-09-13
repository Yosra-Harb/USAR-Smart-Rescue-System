import Feature from "ol/Feature";
import Point from "ol/geom/Point";
import VectorLayer from "ol/layer/Vector";
import VectorSource from "ol/source/Vector";
import CircleStyle from "ol/style/Circle";
import Fill from "ol/style/Fill";
import Stroke from "ol/style/Stroke";
import Style from "ol/style/Style";
import Text from "ol/style/Text";

import type { Victim } from "../../../../../types/victim";
import { LAYER_ORDER } from "../../config/layerOrder";
import type { MapLayer } from "./MapLayer";

export class VictimMapLayer implements MapLayer<VectorLayer<VectorSource<Feature<Point>>>> {
  public readonly id = "victims";
  public readonly zIndex = LAYER_ORDER.VICTIMS;

  private readonly source = new VectorSource<Feature<Point>>();
  private readonly layer = new VectorLayer({
    source: this.source,
    zIndex: this.zIndex,
  });
  private selectedVictimId: number | null = null;

  getLayer(): VectorLayer<VectorSource<Feature<Point>>> {
    return this.layer;
  }

  setVictims(victims: Victim[]): void {
    this.source.clear();
    this.source.addFeatures(victims.map((victim) => this.createFeature(victim)));
  }

  setSelectedVictim(id: number | null): void {
    this.selectedVictimId = id;
    for (const feature of this.source.getFeatures()) {
      const victim = feature.get("victim") as Victim;
      feature.setStyle(this.createVictimStyle(victim, victim.id === id));
    }
  }

  getFeatureByVictimId(id: number): Feature<Point> | null {
    return this.source.getFeatureById(id);
  }

  clear(): void {
    this.source.clear();
  }

  dispose(): void {
    this.clear();
  }

  private createFeature(victim: Victim): Feature<Point> {
    const feature = new Feature<Point>({
      geometry: new Point([victim.position.x, victim.position.y]),
    });
    feature.setId(victim.id);
    feature.setProperties({
      victimId: victim.id,
      featureType: "victim",
      victim,
    });
    feature.setStyle(
      this.createVictimStyle(victim, victim.id === this.selectedVictimId),
    );
    return feature;
  }

  private createVictimStyle(victim: Victim, isSelected: boolean): Style[] {
    const color = victim.provisional
      ? "#f59e0b"
      : victim.priority === "HIGH"
        ? "#ef4444"
        : victim.priority === "MEDIUM"
          ? "#f59e0b"
          : "#22c55e";

    const coordinates = `(${victim.position.x.toFixed(1)}, ${victim.position.y.toFixed(1)})`;
    return [
      new Style({
        image: new CircleStyle({
          radius: isSelected ? 18 : 15,
          stroke: new Stroke({
            color: isSelected ? "#f8fafc" : "rgba(248, 250, 252, 0.75)",
            width: isSelected ? 3 : 2,
            lineDash: victim.provisional ? [4, 3] : undefined,
          }),
        }),
      }),
      new Style({
        image: new CircleStyle({
          radius: isSelected ? 11 : 9,
          fill: new Fill({ color }),
          stroke: new Stroke({ color: "#020617", width: 3 }),
        }),
        text: new Text({
          text: isSelected
            ? `VICTIM #${victim.id}  ${coordinates}`
            : `VICTIM #${victim.id}`,
          offsetY: -30,
          font: "700 11px sans-serif",
          fill: new Fill({ color: "#ffffff" }),
          backgroundFill: new Fill({ color: "rgba(5, 9, 20, 0.92)" }),
          backgroundStroke: new Stroke({ color, width: 1.5 }),
          padding: [4, 6, 4, 6],
        }),
      }),
    ];
  }
}
