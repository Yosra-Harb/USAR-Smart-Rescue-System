import { useState } from "react";

import { missionDataSource } from "./config/missionDataSourceConfig";
import AppShell from "./layouts/AppShell";
import MissionOperationsPage from "./pages/MissionOperationsPage";
import ScenarioCenterPage from "./pages/ScenarioCenterPage";

type Page = "mission" | "scenario";
type ScenarioMode = "fixed" | "generate";

export default function App() {
  const [page, setPage] = useState<Page>("mission");
  const [scenarioMode, setScenarioMode] = useState<ScenarioMode>("fixed");

  function openScenario(mode: ScenarioMode): void {
    setScenarioMode(mode);
    setPage("scenario");
  }

  return (
    <AppShell
      activePage={page}
      onNavigate={(next) => setPage(next)}
    >
      {page === "mission" ? (
        <MissionOperationsPage
          dataSource={missionDataSource}
          onOpenFixedRuns={() => openScenario("fixed")}
          onOpenGenerator={() => openScenario("generate")}
        />
      ) : (
        <ScenarioCenterPage
          initialMode={scenarioMode}
          onMissionStarted={() => setPage("mission")}
        />
      )}
    </AppShell>
  );
}
