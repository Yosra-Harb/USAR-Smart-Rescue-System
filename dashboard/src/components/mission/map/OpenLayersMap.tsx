import { useEffect, useRef } from "react";

import type { GroundTruthVictim } from "../../../types/groundTruth";
import type { Position } from "../../../types/position";
import type {
  RescueRoute,
  RescueRouteMode,
  Victim,
} from "../../../types/victim";

import { MapService } from "./engine";

type OpenLayersMapProps = {
  victims: Victim[];
  groundTruth?: GroundTruthVictim[];
  showGroundTruth: boolean;
  selectedVictimId: number | null;
  onSelectVictim: (id: number) => void;
  probePosition: Position | null;
  probePath: Position[];
  obstacles: Position[];
  rescueRoute: RescueRoute | null;
  rescueRouteMode: RescueRouteMode;
};

export default function OpenLayersMap({
  victims,
  groundTruth,
  showGroundTruth,
  selectedVictimId,
  onSelectVictim,
  probePosition,
  probePath,
  obstacles,
  rescueRoute,
  rescueRouteMode,
}: OpenLayersMapProps) {
  const mapElement = useRef<HTMLDivElement | null>(null);
  const mapService = useRef<MapService | null>(null);
  const onSelectVictimRef = useRef(onSelectVictim);

  useEffect(() => {
    onSelectVictimRef.current = onSelectVictim;
  }, [onSelectVictim]);

  useEffect(() => {
    const target = mapElement.current;
    if (!target) {
      return;
    }

    mapService.current = new MapService(target, (victimId) => {
      onSelectVictimRef.current(victimId);
    });
    mapService.current.updateSize();

    return () => {
      mapService.current?.destroy();
      mapService.current = null;
    };
  }, []);

  useEffect(() => {
    mapService.current?.setVictims(victims);
  }, [victims]);

  useEffect(() => {
    mapService.current?.setGroundTruth(groundTruth ?? []);
  }, [groundTruth]);

  useEffect(() => {
    mapService.current?.setGroundTruthVisible(
      showGroundTruth && Boolean(groundTruth?.length),
    );
  }, [groundTruth, showGroundTruth]);

  useEffect(() => {
    mapService.current?.setSelectedVictim(selectedVictimId);
  }, [selectedVictimId]);

  useEffect(() => {
    mapService.current?.setProbe(probePosition, probePath);
  }, [probePosition, probePath]);

  useEffect(() => {
    mapService.current?.setObstacles(obstacles);
  }, [obstacles]);

  useEffect(() => {
    mapService.current?.setRescueRoute(rescueRoute, rescueRouteMode);
  }, [rescueRoute, rescueRouteMode]);

  return <div ref={mapElement} className="openlayers-map" />;
}
