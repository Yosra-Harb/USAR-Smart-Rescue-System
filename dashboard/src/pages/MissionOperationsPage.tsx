import ScenarioLaunchStatusBar from "../components/scenario/ScenarioLaunchStatusBar";
import MissionWorkspace from "../components/mission/MissionWorkspace";
import type { MissionDataSource } from "../data/missionDataSource";

import "../styles/scenario-center.css";

type MissionOperationsPageProps = {
  dataSource: MissionDataSource;
  onOpenFixedRuns: () => void;
  onOpenGenerator: () => void;
};

export default function MissionOperationsPage({
  dataSource,
  onOpenFixedRuns,
  onOpenGenerator,
}: MissionOperationsPageProps) {
  return (
    <>
      <div className="mission-page-controls">
        <button type="button" onClick={onOpenFixedRuns}>Fixed Runs</button>
        <button type="button" onClick={onOpenGenerator}>Generate Scenario</button>
      </div>
      <ScenarioLaunchStatusBar />
      <MissionWorkspace dataSource={dataSource} />
    </>
  );
}
