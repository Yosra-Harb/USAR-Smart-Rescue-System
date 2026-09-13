import { useEffect, useMemo, useState } from "react";

import type { GroundTruthVictim } from "../../types/groundTruth";
import type { OperationalMapData, ProbeState } from "../../types/mission";
import type { Position } from "../../types/position";
import type { RescueRouteMode, Victim } from "../../types/victim";

import "../../styles/operational-map.css";

import MapCanvas from "./map/MapCanvas";
import RescueRoutePanel from "./map/RescueRoutePanel";
import VictimList from "./map/VictimList";

type OperationalMapProps = {
  victims: Victim[];
  groundTruth?: GroundTruthVictim[];
  selectedVictimId: number | null;
  onSelectVictim: (id: number) => void;
  probe: ProbeState | null;
  probePath: Position[];
  operationalMap: OperationalMapData | null;
  missionCompleted: boolean;
};

export default function OperationalMap({
  victims,
  groundTruth,
  selectedVictimId,
  onSelectVictim,
  probe,
  probePath,
  operationalMap,
  missionCompleted,
}: OperationalMapProps) {
  const [showGroundTruth, setShowGroundTruth] = useState(false);
  const [routeMode, setRouteMode] = useState<RescueRouteMode>("recommended");
  const hasGroundTruth = missionCompleted && Boolean(groundTruth?.length);

  const selectedVictim = useMemo(
    () => victims.find((victim) => victim.id === selectedVictimId) ?? null,
    [selectedVictimId, victims],
  );

  const selectedRoute = selectedVictim
    ? routeMode === "recommended"
      ? selectedVictim.recommendedRoute
      : selectedVictim.shortestRoute
    : null;

  useEffect(() => {
    if (!hasGroundTruth) {
      setShowGroundTruth(false);
    }
  }, [hasGroundTruth]);

  useEffect(() => {
    setRouteMode("recommended");
  }, [selectedVictimId]);

  return (
    <section className="operational-map-widget">
      <div className="widget-header">
        <div>
          <h3>Operational Map</h3>
          <p>
            {missionCompleted
              ? "Final victim locations with exact rescue route geometry"
              : "Live probe path and provisional victim tracks"}
          </p>
        </div>

        <button
          type="button"
          className="ground-truth-toggle"
          disabled={!hasGroundTruth}
          aria-pressed={showGroundTruth}
          onClick={() => setShowGroundTruth((current) => !current)}
        >
          {showGroundTruth ? "Hide Ground Truth" : "Show Ground Truth"}
        </button>
      </div>

      <RescueRoutePanel
        victim={selectedVictim}
        mode={routeMode}
        onModeChange={setRouteMode}
      />

      <div className="operational-map">
        <MapCanvas
          victims={victims}
          groundTruth={groundTruth}
          showGroundTruth={showGroundTruth}
          selectedVictimId={selectedVictimId}
          onSelectVictim={onSelectVictim}
          probe={probe}
          probePath={probePath}
          obstacles={operationalMap?.obstacles ?? []}
          rescueRoute={selectedRoute}
          rescueRouteMode={routeMode}
          missionCompleted={missionCompleted}
        />

        <VictimList
          victims={victims}
          selectedVictimId={selectedVictimId}
          onSelectVictim={onSelectVictim}
        />
      </div>
    </section>
  );
}
