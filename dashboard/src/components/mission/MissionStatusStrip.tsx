import type { MissionStatus } from "../../types/mission";
import StatusCard from "../ui/StatusCard";

import "../../styles/status-strip.css";

type MissionStatusStripProps = {
  status: MissionStatus;
};

export default function MissionStatusStrip({
  status,
}: MissionStatusStripProps) {
  return (
    <section className="mission-status-strip">
      <StatusCard label="Mission Status" value={status.missionStatus} />
      <StatusCard label="Elapsed Time" value={status.elapsedTime} />
      <StatusCard label="Victim Tracks / Final" value={status.detectedVictims} />
      <StatusCard label="Fusion" value={status.fusionStatus} />
      <StatusCard label="Backend" value={status.communicationStatus} />
    </section>
  );
}
