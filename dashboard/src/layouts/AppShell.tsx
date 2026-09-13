import Header from "./Header";
import Sidebar from "./Sidebar";
import MainContent from "./MainContent";

import "../styles/layout.css";

type AppShellProps = {
  children: React.ReactNode;
  activePage: "mission" | "scenario";
  onNavigate: (page: "mission" | "scenario") => void;
};

export default function AppShell({
  children,
  activePage,
  onNavigate,
}: AppShellProps) {
  return (
    <div className="app-shell">
      <Header title="USAR Mission Dashboard" />

      <div className="app-body">
        <Sidebar activePage={activePage} onNavigate={onNavigate} />

        <MainContent>
          {children}
        </MainContent>
      </div>
    </div>
  );
}
