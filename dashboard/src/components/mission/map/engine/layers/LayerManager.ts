import type OpenLayersMap from "ol/Map";

import type { MapLayer } from "./MapLayer";

export class LayerManager {
  private readonly layers = new Map<string, MapLayer>();

  private readonly map: OpenLayersMap;

  constructor(map: OpenLayersMap) {
    this.map = map;
  }

  public register(layer: MapLayer): void {
    if (this.layers.has(layer.id)) {
      throw new Error(
        `A map layer with the id "${layer.id}" is already registered.`,
      );
    }

    const openLayersLayer = layer.getLayer();

    openLayersLayer.setZIndex(layer.zIndex);

    this.layers.set(layer.id, layer);
    this.map.addLayer(openLayersLayer);
  }

  public get(id: string): MapLayer {
    const layer = this.layers.get(id);

    if (!layer) {
      throw new Error(
        `No map layer with the id "${id}" is registered.`,
      );
    }

    return layer;
  }

  public setVisible(
    id: string,
    visible: boolean,
  ): void {
    this.get(id).getLayer().setVisible(visible);
  }

  public dispose(): void {
    for (const layer of this.layers.values()) {
      this.map.removeLayer(layer.getLayer());
      layer.dispose();
    }

    this.layers.clear();
  }
}