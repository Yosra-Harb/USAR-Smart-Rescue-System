import type { Victim } from "../../../types/victim";

import "../../../styles/decision-summary.css";

type DecisionSummaryProps = {
  victim: Victim | null;
  missionDecision: string | null;
  missionCompleted: boolean;
};

export default function DecisionSummary({
  victim,
  missionDecision,
  missionCompleted,
}: DecisionSummaryProps) {
  return (
    <section className="decision-summary">
      <Summary label="Selected Target" value={victim ? `#${victim.id}` : "None"} />
      <Summary label={missionCompleted ? "Last Probe Decision" : "Controller Decision"} value={formatDecision(missionDecision)} />
      <Summary label="Priority" value={victim?.priority ?? "—"} emphasis={victim?.priority === "HIGH"} />
      <Summary label="Rescue Rank" value={victim?.rescueRank === null || !victim ? "—" : `#${victim.rescueRank}`} />
      <Summary label="Vitality Index" value={percent(victim?.vitalityIndex ?? null)} />
      <Summary label="Medical Severity" value={percent(victim?.medicalSeverity ?? null)} />
    </section>
  );
}

type SummaryProps = {
  label: string;
  value: string;
  emphasis?: boolean;
};

function Summary({ label, value, emphasis = false }: SummaryProps) {
  return (
    <div className="summary-item">
      <span className="summary-label">{label}</span>
      <span className={`summary-value ${emphasis ? "high" : ""}`}>
        {value}
      </span>
    </div>
  );
}

function percent(value: number | null): string {
  return value === null ? "—" : `${Math.round(value * 100)}%`;
}

function formatDecision(value: string | null): string {
  return value ? value.replaceAll("_", " ") : "Waiting";
}
