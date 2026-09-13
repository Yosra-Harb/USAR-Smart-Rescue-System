import { useEffect, useRef, useState } from "react";

import "../../styles/mission-workspace.css";

import type { MissionDataSource } from "../../data/missionDataSource";
import { useMissionSnapshot } from "../../hooks/useMissionSnapshot";

import DecisionWorkspace from "./DecisionWorkspace";
import EvaluationSummary from "./EvaluationSummary";
import FusionIntelligence from "./FusionIntelligence";
import MissionDataState from "./MissionDataState";
import MissionStatusStrip from "./MissionStatusStrip";
import OperationalMap from "./OperationalMap";
import Timeline from "./Timeline";
import VictimIntelligence from "./VictimIntelligence";
import SensorReadings from "./victim/SensorReadings";

type MissionWorkspaceProps = {
  dataSource: MissionDataSource;
};

export default function MissionWorkspace({
  dataSource,
}: MissionWorkspaceProps) {
  const [selectedVictimId, setSelectedVictimId] =
    useState<number | null>(null);
  const lastSelectionStage = useRef<string | null>(null);

  const {
    snapshot,
    error: loadError,
    isLoading,
    reload,
  } = useMissionSnapshot(dataSource, {
    pollingIntervalMs: 750,
  });

  useEffect(() => {
    if (!snapshot) {
      lastSelectionStage.current = null;
      setSelectedVictimId(null);
      return;
    }

    const hasFinalVictims =
      snapshot.status.missionStatus === "COMPLETED" &&
      snapshot.victims.some((victim) => !victim.provisional);
    const selectionStage =
      `${snapshot.missionId}:${hasFinalVictims ? "final" : "live"}`;
    const enteredNewStage = lastSelectionStage.current !== selectionStage;
    lastSelectionStage.current = selectionStage;

    if (snapshot.victims.length === 0) {
      setSelectedVictimId(null);
      return;
    }

    setSelectedVictimId((currentId) => {
      if (enteredNewStage) {
        return snapshot.victims[0].id;
      }

      const stillExists =
        currentId !== null &&
        snapshot.victims.some(
          (victim) => victim.id === currentId,
        );

      return stillExists
        ? currentId
        : snapshot.victims[0].id;
    });
  }, [snapshot]);

  if (loadError) {
    const noMissionYet =
      loadError.toLowerCase().includes("no mission") ||
      loadError.toLowerCase().includes("mission_not_found");

    return (
      <MissionDataState
        variant={noMissionYet ? "loading" : "error"}
        title={noMissionYet ? "No mission started yet" : "Backend connection unavailable"}
        message={
          noMissionYet
            ? "Use Fixed Runs or Generate Scenario above to start MATLAB directly from the dashboard."
            : loadError
        }
        onRetry={reload}
      />
    );
  }

  if (!snapshot) {
    return (
      <MissionDataState
        variant="loading"
        title="Connecting to live mission"
        message="Waiting for FastAPI mission state and MATLAB telemetry."
      />
    );
  }

  const selectedVictim =
    snapshot.victims.find(
      (victim) => victim.id === selectedVictimId,
    ) ?? null;

  return (
    <main
      className="mission-workspace"
      aria-busy={isLoading}
    >
      <div className="mission-connection-bar">
        <span className="mission-connection-dot" />
        <strong>{snapshot.status.missionStatus === "RUNNING" ? "LIVE DATA" : "MISSION RESULT"}</strong>
        <span>{snapshot.missionId}</span>
        <span className="mission-connection-sequence">
          Seq {snapshot.status.lastSequence}
        </span>
      </div>

      <MissionStatusStrip status={snapshot.status} />

      <section className="workspace-map">
        <OperationalMap
          victims={snapshot.victims}
          groundTruth={snapshot.groundTruth}
          selectedVictimId={selectedVictim?.id ?? null}
          onSelectVictim={setSelectedVictimId}
          probe={snapshot.probe}
          probePath={snapshot.probePath}
          operationalMap={snapshot.operationalMap}
          missionCompleted={
            snapshot.status.missionStatus === "COMPLETED"
          }
        />
      </section>

      <section className="workspace-grid">
        <DecisionWorkspace
          victim={selectedVictim}
          missionDecision={snapshot.decision}
          missionCompleted={snapshot.status.missionStatus === "COMPLETED"}
        />

        <VictimIntelligence victim={selectedVictim} />

        <Timeline
          events={snapshot.events}
          selectedVictimId={selectedVictim?.id ?? null}
          onSelectVictim={setSelectedVictimId}
        />

        <FusionIntelligence
          fusion={snapshot.fusion}
          sensors={snapshot.sensors}
          missionCompleted={snapshot.status.missionStatus === "COMPLETED"}
        />

        <SensorReadings
          sensors={snapshot.sensors}
          missionCompleted={snapshot.status.missionStatus === "COMPLETED"}
        />

        <EvaluationSummary evaluation={snapshot.evaluation} />
      </section>
    </main>
  );
}
