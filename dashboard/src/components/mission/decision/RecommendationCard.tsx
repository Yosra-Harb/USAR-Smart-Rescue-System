import type { Victim } from "../../../types/victim";

import "../../../styles/recommendation-card.css";

type RecommendationCardProps = {
  victim: Victim | null;
};

export default function RecommendationCard({
  victim,
}: RecommendationCardProps) {
  if (!victim) {
    return (
      <section className="recommendation-card recommendation-card--empty">
        <span className="recommendation-title">Recommended Action</span>
        <h3>Continue Mission Search</h3>
        <p className="recommendation-description">
          No victim track is selected yet. The dashboard is following live MATLAB telemetry.
        </p>
      </section>
    );
  }

  const action = recommendation(victim);

  return (
    <section className="recommendation-card">
      <div className="recommendation-top">
        <div>
          <span className="recommendation-title">Recommended Action</span>
          <h3>{action}</h3>
        </div>

        <span className={`recommendation-badge recommendation-badge--${victim.priority.toLowerCase()}`}>
          {victim.priority}
        </span>
      </div>

      <p className="recommendation-description">
        {victim.provisional
          ? "This is a provisional live track. Keep collecting independent evidence before treating it as a final victim record."
          : "This recommendation uses the final MATLAB rescue rank, reachability and route assessment."}
      </p>

      <div className="recommendation-metrics">
        <Metric label="Track State" value={victim.provisional ? "Provisional" : "Final"} />
        <Metric label="Reachable" value={victim.reachable === null ? "Pending" : victim.reachable ? "Yes" : "No"} />
        <Metric label="Route Length" value={victim.recommendedRoute?.pathLength === null || !victim.recommendedRoute ? "—" : `${victim.recommendedRoute.pathLength.toFixed(2)} cells`} />
      </div>
    </section>
  );
}

type MetricProps = { label: string; value: string };
function Metric({ label, value }: MetricProps) {
  return (
    <div className="metric">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function recommendation(victim: Victim): string {
  if (victim.provisional) {
    return "Continue Track Confirmation";
  }
  if (victim.reachable === false) {
    return "Assess Safe Access Point";
  }
  if (victim.rescueRank === 1) {
    return "Prioritize for Rescue";
  }
  return "Follow Rescue Ranking";
}
