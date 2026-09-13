import type { EventsKey } from "ol/events";
import Select, {
  type SelectEvent,
} from "ol/interaction/Select";
import type OpenLayersMap from "ol/Map";
import { unByKey } from "ol/Observable";

import type { VictimMapLayer } from "../layers/VictimMapLayer";

export type VictimSelectHandler = (
  victimId: number,
) => void;

export class VictimSelectionInteraction {
  private readonly map: OpenLayersMap;

  private readonly victimLayer: VictimMapLayer;

  private readonly selectInteraction: Select;

  private readonly selectListenerKey: EventsKey;

  private readonly onSelectVictim: VictimSelectHandler;

  constructor(
    map: OpenLayersMap,
    victimLayer: VictimMapLayer,
    onSelectVictim: VictimSelectHandler,
  ) {
    this.map = map;
    this.victimLayer = victimLayer;
    this.onSelectVictim = onSelectVictim;

    this.selectInteraction = new Select({
      layers: [this.victimLayer.getLayer()],
      style: null,
      hitTolerance: 6,
    });

    this.selectListenerKey = this.selectInteraction.on(
      "select",
      (event) => {
        this.handleSelect(event);
      },
    );

    this.map.addInteraction(this.selectInteraction);
  }

  public setSelectedVictim(id: number | null): void {
    const selectedFeatures =
      this.selectInteraction.getFeatures();

    selectedFeatures.clear();

    if (id === null) {
      return;
    }

    const feature =
      this.victimLayer.getFeatureByVictimId(id);

    if (feature) {
      selectedFeatures.push(feature);
    }
  }

  public dispose(): void {
    unByKey(this.selectListenerKey);
    this.selectInteraction.getFeatures().clear();
    this.map.removeInteraction(this.selectInteraction);
  }

  private handleSelect(event: SelectEvent): void {
    const feature = event.selected[0];

    if (!feature) {
      return;
    }

    const victimId = feature.get("victimId");

    if (typeof victimId !== "number") {
      return;
    }

    this.onSelectVictim(victimId);
  }
}