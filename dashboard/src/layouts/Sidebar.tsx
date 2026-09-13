import "../styles/sidebar.css";

type SidebarProps = {
  activePage: "mission" | "scenario";
  onNavigate: (page: "mission" | "scenario") => void;
};

export default function Sidebar({ activePage, onNavigate }: SidebarProps) {
  return (
    <aside className="sidebar">
      <nav>
        <ul>
          <li className={activePage === "mission" ? "is-active" : ""}>
            <button type="button" onClick={() => onNavigate("mission")}>Mission Operations</button>
          </li>
          <li className={activePage === "scenario" ? "is-active" : ""}>
            <button type="button" onClick={() => onNavigate("scenario")}>Scenario Center</button>
          </li>
          <li className="is-disabled"><span>Experiment Center</span></li>
          <li className="is-disabled"><span>Analytics</span></li>
          <li className="is-disabled"><span>Settings</span></li>
        </ul>
      </nav>
    </aside>
  );
}
