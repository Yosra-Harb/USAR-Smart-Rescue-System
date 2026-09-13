import type { MissionEvaluation } from "../../types/mission";

import DashboardWidget from "../ui/DashboardWidget";
import "../../styles/evaluation-summary.css";

type EvaluationSummaryProps = {
  evaluation: MissionEvaluation | null;
};

export default function EvaluationSummary({
  evaluation,
}: EvaluationSummaryProps) {
  return (
    <DashboardWidget title="Post-Mission Evaluation">
      {!evaluation ? (
        <div className="evaluation-summary__locked">
          <span>Evaluation locked</span>
          <p>
            Ground truth and performance metrics are released only after MISSION_COMPLETED.
          </p>
        </div>
      ) : (
        <section className="evaluation-summary">
          <Metric label="Precision" value={percent(evaluation.precision)} />
          <Metric label="Recall" value={percent(evaluation.recall)} />
          <Metric label="F1" value={percent(evaluation.f1Score)} />
          <Metric label="CSI" value={percent(evaluation.criticalSuccessIndex)} />
          <Metric label="TP / FP / FN" value={`${number(evaluation.truePositives)} / ${number(evaluation.falsePositives)} / ${number(evaluation.falseNegatives)}`} />
          <Metric label="Mean Localization Error" value={cells(evaluation.localizationMeanError)} />
          <Metric label="Localization RMSE" value={cells(evaluation.localizationRmse)} />
          <Metric label="Maximum Error" value={cells(evaluation.localizationMaxError)} />
        </section>
      )}
    </DashboardWidget>
  );
}

type MetricProps = { label: string; value: string };
function Metric({ label, value }: MetricProps) {
  return (
    <div className="evaluation-summary__metric">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function percent(value: number | null): string {
  return value === null ? "—" : `${(value * 100).toFixed(1)}%`;
}
function number(value: number | null): string {
  return value === null ? "—" : String(value);
}
function cells(value: number | null): string {
  return value === null ? "—" : `${value.toFixed(3)} cells`;
}
