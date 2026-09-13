import type { Victim } from "../../types/victim";

import DashboardWidget from "../ui/DashboardWidget";

import DecisionSummary from "./decision/DecisionSummary";
import RecommendationCard from "./decision/RecommendationCard";
import AIExplanation from "./decision/AIExplanation";

type DecisionWorkspaceProps = {
  victim: Victim | null;
  missionDecision: string | null;
  missionCompleted: boolean;
};

export default function DecisionWorkspace({
  victim,
  missionDecision,
  missionCompleted,
}: DecisionWorkspaceProps) {
  return (
    <DashboardWidget title="Decision Workspace">
      <DecisionSummary
        victim={victim}
        missionDecision={missionDecision}
        missionCompleted={missionCompleted}
      />

      {missionCompleted && (
        <p
          style={{
            margin: "10px 0 14px",
            color: "var(--muted)",
            fontSize: ".72rem",
            lineHeight: 1.5,
          }}
        >
          Last probe decision describes search activity. The recommendation below
          is post-mission rescue guidance based on the final victim assessment.
        </p>
      )}

      <RecommendationCard victim={victim} />

      <AIExplanation victim={victim} />
    </DashboardWidget>
  );
}
