import type { Victim } from "../../../types/victim";

import VictimCard from "./VictimCard";
import "../../../styles/victim-list.css";

type VictimListProps = {
  victims: Victim[];
  selectedVictimId: number | null;
  onSelectVictim: (id: number) => void;
};

export default function VictimList({
  victims,
  selectedVictimId,
  onSelectVictim,
}: VictimListProps) {
  const provisional = victims.some((victim) => victim.provisional);

  return (
    <aside className="victim-list">
      <div className="victim-list-header">
        <h3>{provisional ? "Active Tracks" : "Final Victims"}</h3>
        <span>{victims.length}</span>
      </div>
      {victims.length > 0 && (
        <p className="victim-list-note">
          {provisional
            ? "Provisional order by current priority score; rescue routes pending."
            : "MATLAB rescue rank: estimated VI and route feasibility (simulation only)."}
        </p>
      )}

      <div className="victim-list-content">
        {victims.length === 0 ? (
          <p className="victim-list-empty">No victim tracks yet.</p>
        ) : (
          victims.map((victim) => (
            <VictimCard
              key={victim.id}
              victim={victim}
              isSelected={victim.id === selectedVictimId}
              onSelect={onSelectVictim}
            />
          ))
        )}
      </div>
    </aside>
  );
}
