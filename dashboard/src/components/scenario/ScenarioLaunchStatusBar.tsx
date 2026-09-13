import { useScenarioRunStatus } from "../../hooks/useScenarioRunStatus";

import "../../styles/scenario-center.css";

export default function ScenarioLaunchStatusBar() {
  const run = useScenarioRunStatus(900);

  if (!run || run.status === "IDLE") {
    return null;
  }

  const live = run.status === "RUNNING";
  const failed = run.status === "FAILED";

  return (
    <div
      className={`scenario-launch-bar${
        failed ? " scenario-launch-bar--failed" : ""
      }`}
      role="status"
      aria-live="polite"
    >
      <span
        className={`scenario-launch-bar__dot${
          live ? " scenario-launch-bar__dot--live" : ""
        }`}
      />

      <strong>{formatStatus(run.status)}</strong>

      <span>{formatMessage(run.status, run.message)}</span>

      {run.missionId && (
        <span className="scenario-launch-bar__mission">
          {run.missionId}
        </span>
      )}
    </div>
  );
}

function formatStatus(status: string): string {
  switch (status) {
    case "STARTING_MATLAB":
      return "STARTING MATLAB";

    case "RUNNING":
      return "MISSION RUNNING";

    case "COMPLETED":
      return "MISSION COMPLETED";

    case "FAILED":
      return "MISSION FAILED";

    default:
      return status.replaceAll("_", " ");
  }
}

function formatMessage(
  status: string,
  backendMessage?: string | null,
): string {
  switch (status) {
    case "STARTING_MATLAB":
      return "Initializing MATLAB and preparing mission. This may take a few seconds.";

    case "RUNNING":
      return "Live mission telemetry received.";

    case "COMPLETED":
      return "Mission completed successfully.";

    case "FAILED":
      return backendMessage || "Mission launch failed.";

    default:
      return backendMessage || "";
  }
}