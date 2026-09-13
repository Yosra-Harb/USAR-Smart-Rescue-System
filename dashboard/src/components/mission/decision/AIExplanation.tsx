import type { Victim } from "../../../types/victim";

import "../../../styles/ai-explanation.css";

type AIExplanationProps = {
  victim: Victim | null;
};

export default function AIExplanation({
  victim,
}: AIExplanationProps) {
  return (
    <section className="ai-explanation">
      <h4>Decision Evidence</h4>
      <p>{explain(victim)}</p>
    </section>
  );
}

function explain(victim: Victim | null): string {
  if (!victim) {
    return "Waiting for a victim track. All values shown here come from the MATLAB operational contract through the FastAPI backend.";
  }

  const vitality = victim.vitalityIndex === null
    ? "unknown vitality"
    : `${Math.round(victim.vitalityIndex * 100)}% vitality`;
  const severity = victim.medicalSeverity === null
    ? "unknown medical severity"
    : `${Math.round(victim.medicalSeverity * 100)}% simulated medical severity`;
  const rank = victim.rescueRank === null
    ? "no rescue rank yet"
    : `rescue rank #${victim.rescueRank}`;

  return `Victim/track #${victim.id} currently has ${vitality}, ${severity}, priority ${victim.priority}, and ${rank}. The dashboard displays these values; it does not recompute MATLAB inference.`;
}
