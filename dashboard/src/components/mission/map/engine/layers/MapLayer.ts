import type BaseLayer from "ol/layer/Base";

export interface MapLayer<
  TLayer extends BaseLayer = BaseLayer,
> {
  readonly id: string;

  readonly zIndex: number;

  getLayer(): TLayer;

  dispose(): void;
}