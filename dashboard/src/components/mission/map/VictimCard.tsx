import type { Victim } from "../../../types/victim";

import "../../../styles/victim-card.css";

type VictimCardProps = {
  victim: Victim;
  isSelected: boolean;
  onSelect: (id: number) => void;
};

export default function VictimCard({
  victim,
  isSelected,
  onSelect,
}: VictimCardProps) {
  return (
    <button
      type="button"
      className={`victim-card ${isSelected ? "selected" : ""}`}
      onClick={() => onSelect(victim.id)}
    >
      <div className="victim-card-header">
        <h4>
          {victim.provisional ? "Track" : "Victim"} #{victim.id}
        </h4>

        <span
          className={`priority ${victim.priority.toLowerCase()}`}
        >
          {victim.priority} PRIORITY
        </span>
      </div>

      <div className="victim-card-body">
        <p>
          <strong>VI:</strong>{" "}
          {percent(victim.vitalityIndex)}
        </p>

        <p>
          <strong>Rank:</strong>{" "}
          {victim.provisional ||
          victim.rescueRank === null
            ? "Pending"
            : `#${victim.rescueRank}`}
        </p>

        <p>
          <strong>Route Distance:</strong>{" "}
          {routeLength(victim)}
        </p>

        {!victim.provisional && (
          <>
            <p>
              <strong>Access:</strong>{" "}
              {victim.reachable === null
                ? "Unknown"
                : victim.reachable
                  ? "Reachable"
                  : "No route"}
            </p>

            <p>
              <strong>Priority Score:</strong>{" "}
              {victim.priorityScore === null
                ? "—"
                : victim.priorityScore.toFixed(3)}
            </p>
          </>
        )}
      </div>
    </button>
  );
}

function percent(
  value: number | null,
): string {
  return value === null
    ? "—"
    : `${Math.round(value * 100)}%`;
}

function routeLength(
  victim: Victim,
): string {
  const length =
    victim.recommendedRoute?.pathLength;

  return length === null ||
    length === undefined
    ? "—"
    : `${length.toFixed(1)} grid`;
}