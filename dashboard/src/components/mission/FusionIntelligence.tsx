import type {
  MissionFusion,
  MissionSensors,
} from "../../types/fusion";

import "../../styles/fusion-intelligence.css";

import DashboardWidget from "../ui/DashboardWidget";

type FusionIntelligenceProps = {
  fusion: MissionFusion | null;
  sensors: MissionSensors | null;
  missionCompleted: boolean;
};

export default function FusionIntelligence({
  fusion,
  sensors,
  missionCompleted,
}: FusionIntelligenceProps) {
  return (
    <DashboardWidget title={missionCompleted ? "Last Sensor Fusion Reading" : "Live Fusion Intelligence"}>
      {!fusion || fusion.score === null ? (
        <p className="fusion-intelligence__empty">
          Waiting for a MATLAB fusion record.
        </p>
      ) : (
        <section className="fusion-intelligence">
          <div className="fusion-intelligence__summary">
            <div>
              <span className="fusion-intelligence__label">
                {missionCompleted ? "Last probe fused score" : "Current fused score"}
              </span>
              <strong className="fusion-intelligence__score">
                {percent(fusion.score)}
              </strong>
            </div>
            <div>
              <span className="fusion-intelligence__label">
                Confidence
              </span>
              <strong className="fusion-intelligence__score fusion-intelligence__score--secondary">
                {percent(fusion.confidence)}
              </strong>
            </div>
          </div>

          {missionCompleted && (
            <p className="fusion-intelligence__context">
              Final probe telemetry, not the selected victim's detection score.
            </p>
          )}

          <div className="fusion-intelligence__meter">
            <span style={{ width: percent(fusion.score) }} />
          </div>

          <div className="fusion-intelligence__table-wrapper">
            <table className="fusion-intelligence__table">
              <thead>
                <tr>
                  <th>Sensor</th>
                  <th>Reading</th>
                  <th>Reliability</th>
                  <th>Weight</th>
                </tr>
              </thead>
              <tbody>
                <FusionRow
                  label="UWB Radar"
                  reading={sensors?.radar.normalized ?? null}
                  reliability={sensors?.radar.reliability ?? null}
                  weight={fusion.weights.radar}
                />
                <FusionRow
                  label="Thermal"
                  reading={sensors?.thermal.normalized ?? null}
                  reliability={sensors?.thermal.reliability ?? null}
                  weight={fusion.weights.thermal}
                />
                <FusionRow
                  label="Acoustic"
                  reading={sensors?.acoustic.normalized ?? null}
                  reliability={sensors?.acoustic.reliability ?? null}
                  weight={fusion.weights.acoustic}
                />
              </tbody>
            </table>
          </div>
        </section>
      )}
    </DashboardWidget>
  );
}

type FusionRowProps = {
  label: string;
  reading: number | null;
  reliability: number | null;
  weight: number | null;
};

function FusionRow({
  label,
  reading,
  reliability,
  weight,
}: FusionRowProps) {
  return (
    <tr>
      <th scope="row">{label}</th>
      <td>{percent(reading)}</td>
      <td>{percent(reliability)}</td>
      <td>{percent(weight)}</td>
    </tr>
  );
}

function percent(value: number | null): string {
  return value === null ? "—" : `${Math.round(value * 100)}%`;
}
