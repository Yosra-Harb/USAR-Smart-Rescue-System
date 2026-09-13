import type { GroundTruthVictim } from "../../../types/groundTruth";
import type { ProbeState } from "../../../types/mission";
import type { Position } from "../../../types/position";
import type {
  RescueRoute,
  RescueRouteMode,
  Victim,
} from "../../../types/victim";

import { LAYER_ORDER } from "./config/layerOrder";
import GridLabels from "./overlays/GridLabels";
import NorthArrow from "./overlays/NorthArrow";
import ScaleBar from "./overlays/ScaleBar";
import OpenLayersMap from "./OpenLayersMap";
import LayerContainer from "./shared/LayerContainer";

type MapCanvasProps = {
  victims: Victim[];
  groundTruth?: GroundTruthVictim[];
  showGroundTruth: boolean;
  selectedVictimId: number | null;
  onSelectVictim: (id: number) => void;
  probe: ProbeState | null;
  probePath: Position[];
  obstacles: Position[];
  rescueRoute: RescueRoute | null;
  rescueRouteMode: RescueRouteMode;
  missionCompleted: boolean;
};

export default function MapCanvas({
  victims,
  groundTruth,
  showGroundTruth,
  selectedVictimId,
  onSelectVictim,
  probe,
  probePath,
  obstacles,
  rescueRoute,
  rescueRouteMode,
  missionCompleted,
}: MapCanvasProps) {
  return (
    <div className="map-canvas">
      <LayerContainer zIndex={LAYER_ORDER.BACKGROUND} interactive>
        <OpenLayersMap
          victims={victims}
          groundTruth={groundTruth}
          showGroundTruth={showGroundTruth}
          selectedVictimId={selectedVictimId}
          onSelectVictim={onSelectVictim}
          probePosition={probe?.position ?? null}
          probePath={probePath}
          obstacles={obstacles}
          rescueRoute={rescueRoute}
          rescueRouteMode={rescueRouteMode}
        />
      </LayerContainer>

      <LayerContainer zIndex={LAYER_ORDER.UI}>
        <>
          <NorthArrow />
          <ScaleBar />
          <GridLabels />
          <div className="map-live-label">
            {!missionCompleted && <span className="map-live-dot" />}
            {missionCompleted ? "MISSION RESULT" : "MATLAB LIVE"}
          </div>
          <div className="map-route-legend">
            <span><i className="legend-swatch obstacle" />Obstacle</span>
            <span><i className={`legend-swatch route ${rescueRouteMode}`} />
              {rescueRouteMode === "recommended" ? "Recommended route" : "Shortest route"}
            </span>
            <span><i className="legend-swatch probe" />Probe scan</span>
            <span><i className="legend-swatch victim" />Victim location</span>
            {showGroundTruth && <span><i className="legend-swatch truth" />True location</span>}
            <span><i className="legend-swatch start" />Rescue start</span>
            <span><i className="legend-swatch access" />Access point</span>
          </div>
        </>
      </LayerContainer>
    </div>
  );
}
