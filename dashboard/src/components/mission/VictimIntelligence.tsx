import type { Victim } from "../../types/victim";

import DashboardWidget from "../ui/DashboardWidget";
import VictimProfile from "./victim/VictimProfile";

import "../../styles/victim-intelligence.css";

type VictimIntelligenceProps = {
  victim: Victim | null;
};

export default function VictimIntelligence({
  victim,
}: VictimIntelligenceProps) {
  return (
    <DashboardWidget title="Victim Intelligence">
      {!victim ? (
        <p className="victim-intelligence__empty">
          No victim track is selected.
        </p>
      ) : (
        <>
          <VictimProfile victim={victim} />
          <div className="victim-intelligence__metrics">
            <Metric label="Position" value={`(${victim.position.x.toFixed(1)}, ${victim.position.y.toFixed(1)})`} />
            <Metric label="Priority Score" value={decimal(victim.priorityScore)} />
            <Metric label="Independent Views" value={victim.independentViewCount === null ? "—" : String(victim.independentViewCount)} />
            <Metric label="Route Risk" value={decimal(victim.recommendedRoute?.meanRisk ?? null)} />
            <Metric label="Route Accessibility" value={decimal(victim.recommendedRoute?.meanAccessibility ?? null)} />
            <Metric label="Last Telemetry" value={victim.lastUpdate} />
          </div>
        </>
      )}
    </DashboardWidget>
  );
}

type MetricProps = { label: string; value: string };
function Metric({ label, value }: MetricProps) {
  return (
    <div className="victim-intelligence__metric">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function decimal(value: number | null): string {
  return value === null ? "—" : value.toFixed(3);
}
