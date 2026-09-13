import type { Victim } from "../../../types/victim";

import "../../../styles/victim-profile.css";

type VictimProfileProps = {
  victim: Victim;
};

export default function VictimProfile({
  victim,
}: VictimProfileProps) {
  return (
    <section className="victim-profile">
      <div className="victim-profile__title-row">
        <h3>{victim.provisional ? "Track" : "Victim"} #{victim.id}</h3>
        <span className={victim.provisional ? "track-badge" : "final-badge"}>
          {victim.provisional ? "PROVISIONAL" : "FINAL"}
        </span>
      </div>

      <div className="profile-grid">
        <Profile label="Condition" value={victim.status} />
        <Profile label="Priority" value={victim.priority} />
        <Profile label="Vitality Index" value={percent(victim.vitalityIndex)} />
        <Profile label="Medical Severity" value={percent(victim.medicalSeverity)} />
        <Profile label="Rescue Rank" value={victim.rescueRank === null ? "—" : `#${victim.rescueRank}`} />
        <Profile label="Reachable" value={victim.reachable === null ? "Pending" : victim.reachable ? "Yes" : "No"} />
      </div>
    </section>
  );
}

type ProfileProps = { label: string; value: string };
function Profile({ label, value }: ProfileProps) {
  return (
    <div className="profile-row">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function percent(value: number | null): string {
  return value === null ? "—" : `${Math.round(value * 100)}%`;
}
