import type {
  RescueRoute,
  RescueRouteMode,
  Victim,
} from "../../../types/victim";

import "../../../styles/rescue-route.css";

type RescueRoutePanelProps = {
  victim: Victim | null;
  mode: RescueRouteMode;
  onModeChange: (mode: RescueRouteMode) => void;
};

export default function RescueRoutePanel({
  victim,
  mode,
  onModeChange,
}: RescueRoutePanelProps) {
  if (!victim || victim.provisional) {
    return (
      <div className="rescue-route-panel muted">
        <div>
          <strong>Rescue Route</strong>
          <span>Select a final victim after mission completion to display the exact route.</span>
        </div>
      </div>
    );
  }

  const route = routeFor(victim, mode);
  const alternate = routeFor(victim, mode === "recommended" ? "shortest" : "recommended");
  const hasCurrent = Boolean(route?.reachable && route.path.length > 0);
  const waypoints = hasCurrent ? compressToTurns(route as RescueRoute) : [];

  return (
    <div className="rescue-route-panel">
      <div className="route-panel-topline">
        <div>
          <strong>Route to Victim #{victim.id}</strong>
          <span>
            Exact A* path from rescue entry/start to the victim access point.
          </span>
        </div>

        <div className="route-mode-toggle" role="group" aria-label="Rescue route mode">
          <button
            type="button"
            className={mode === "recommended" ? "active recommended" : ""}
            onClick={() => onModeChange("recommended")}
            disabled={!victim.recommendedRoute}
          >
            Recommended
          </button>
          <button
            type="button"
            className={mode === "shortest" ? "active shortest" : ""}
            onClick={() => onModeChange("shortest")}
            disabled={!victim.shortestRoute}
          >
            Shortest
          </button>
        </div>
      </div>

      {!hasCurrent ? (
        <div className="route-unavailable">
          Route unavailable for this victim.
          {alternate?.reachable ? " Try the other route mode." : ""}
        </div>
      ) : (
        <>
          <div className="route-metrics">
            <Metric label="Length" value={formatGridLength(route?.pathLength)} />
            <Metric label="Path nodes" value={String(route?.path.length ?? 0)} />
            <Metric label="Mean risk" value={formatPercent(route?.meanRisk)} />
            <Metric label="Accessibility" value={formatPercent(route?.meanAccessibility)} />
            <Metric label="Start" value={formatPoint(route?.path[0] ?? null)} />
            <Metric label="Access" value={formatPoint(route?.accessPoint ?? null)} />
          </div>

          <div className="route-waypoints">
            <span className="route-waypoints-label">Turn-by-turn waypoints</span>
            <div className="route-waypoint-flow">
              {waypoints.map((point, index) => (
                <span key={`${point.x}-${point.y}-${index}`} className="route-waypoint">
                  {index === 0 ? "START " : index === waypoints.length - 1 ? "ACCESS " : ""}
                  ({formatCoordinate(point.x)}, {formatCoordinate(point.y)})
                </span>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}

function routeFor(victim: Victim, mode: RescueRouteMode): RescueRoute | null {
  return mode === "recommended"
    ? victim.recommendedRoute
    : victim.shortestRoute;
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="route-metric">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function compressToTurns(route: RescueRoute): RescueRoute["path"] {
  const path = route.path;
  if (path.length <= 2) {
    return path;
  }

  const turns = [path[0]];
  let previousDirection = direction(path[0], path[1]);

  for (let index = 1; index < path.length - 1; index += 1) {
    const nextDirection = direction(path[index], path[index + 1]);
    if (
      nextDirection.x !== previousDirection.x ||
      nextDirection.y !== previousDirection.y
    ) {
      turns.push(path[index]);
      previousDirection = nextDirection;
    }
  }

  turns.push(path[path.length - 1]);
  return turns;
}

function direction(first: RescueRoute["path"][number], second: RescueRoute["path"][number]) {
  return {
    x: Math.sign(second.x - first.x),
    y: Math.sign(second.y - first.y),
  };
}

function formatGridLength(value: number | null | undefined): string {
  return value === null || value === undefined
    ? "—"
    : `${value.toFixed(2)} grid units`;
}

function formatPercent(value: number | null | undefined): string {
  return value === null || value === undefined
    ? "—"
    : `${Math.round(value * 100)}%`;
}

function formatPoint(value: RescueRoute["accessPoint"]): string {
  return value ? `(${formatCoordinate(value.x)}, ${formatCoordinate(value.y)})` : "—";
}

function formatCoordinate(value: number): string {
  return Number.isInteger(value) ? String(value) : value.toFixed(1);
}
