import DashboardWidget from "../ui/DashboardWidget";
import type { MissionEvent } from "../../types/missionEvent";

import "../../styles/timeline.css";

type TimelineProps = {
  events: MissionEvent[];
  selectedVictimId: number | null;
  onSelectVictim: (victimId: number) => void;
};

function formatElapsedTime(totalSeconds: number): string {
  const roundedSeconds = Math.floor(totalSeconds);
  const hours = Math.floor(roundedSeconds / 3600);
  const minutes = Math.floor(
    (roundedSeconds % 3600) / 60,
  );
  const seconds = roundedSeconds % 60;

  return [hours, minutes, seconds]
    .map((part) => String(part).padStart(2, "0"))
    .join(":");
}

export default function Timeline({
  events,
  selectedVictimId,
  onSelectVictim,
}: TimelineProps) {
  const orderedEvents = [...events].sort(
    (first, second) =>
      second.elapsedSeconds - first.elapsedSeconds,
  );

  return (
    <DashboardWidget title="Timeline">
      {orderedEvents.length === 0 ? (
        <p className="mission-timeline__empty">
          No mission events have been reported yet.
        </p>
      ) : (
        <ol className="mission-timeline">
          {orderedEvents.map((event) => {
            const victimId = event.victimId;
            const isSelectable =
              victimId !== undefined;
            const isSelected =
              isSelectable &&
              victimId === selectedVictimId;

            const entryClassName = [
              "mission-timeline__entry",
              isSelected
                ? "mission-timeline__entry--selected"
                : "",
            ]
              .filter(Boolean)
              .join(" ");

            const content = (
              <>
                <div className="mission-timeline__meta">
                  <time className="mission-timeline__time">
                    {formatElapsedTime(
                      event.elapsedSeconds,
                    )}
                  </time>

                  <span className="mission-timeline__category">
                    {event.category}
                  </span>
                </div>

                <h4 className="mission-timeline__title">
                  {event.title}
                </h4>

                <p className="mission-timeline__description">
                  {event.description}
                </p>
              </>
            );

            return (
              <li
                key={event.id}
                className="mission-timeline__item"
              >
                <span
                  className={`mission-timeline__marker mission-timeline__marker--${event.category.toLowerCase()}`}
                  aria-hidden="true"
                />

                {isSelectable ? (
                  <button
                    type="button"
                    className={entryClassName}
                    aria-pressed={isSelected}
                    onClick={() =>
                      onSelectVictim(victimId)
                    }
                  >
                    {content}
                  </button>
                ) : (
                  <div className={entryClassName}>
                    {content}
                  </div>
                )}
              </li>
            );
          })}
        </ol>
      )}
    </DashboardWidget>
  );
}