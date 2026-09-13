import type { MissionSensors } from "../../../types/fusion";

import "../../../styles/sensor-readings.css";

import DashboardWidget from "../../ui/DashboardWidget";

type SensorReadingsProps = {
  sensors: MissionSensors | null;
  missionCompleted: boolean;
};

export default function SensorReadings({
  sensors,
  missionCompleted,
}: SensorReadingsProps) {
  return (
    <DashboardWidget title={missionCompleted ? "Last Sensor Readings" : "Live Sensor Readings"}>
      {!sensors ? (
        <p className="sensor-readings__empty">
          Waiting for sensor telemetry.
        </p>
      ) : (
        <section className="sensor-readings">
          <SensorItem label="UWB Radar" sensor={sensors.radar} />
          <SensorItem label="Thermal" sensor={sensors.thermal} />
          <SensorItem label="Acoustic" sensor={sensors.acoustic} />
          <div className="sensor-item sensor-item--quality">
            <span>Packet Quality</span>
            <strong>{percent(sensors.quality)}</strong>
          </div>
        </section>
      )}
    </DashboardWidget>
  );
}

type SensorItemProps = {
  label: string;
  sensor: MissionSensors["radar"];
};

function SensorItem({ label, sensor }: SensorItemProps) {
  const physical = sensor.physical === null
    ? "—"
    : `${formatNumber(sensor.physical)}${sensor.unit ? ` ${sensor.unit}` : ""}`;

  return (
    <div className="sensor-item">
      <div>
        <span>{label}</span>
        <small>Reliability {percent(sensor.reliability)}</small>
      </div>
      <div className="sensor-item__values">
        <strong>{physical}</strong>
        <em>{percent(sensor.normalized)} normalized</em>
      </div>
    </div>
  );
}

function percent(value: number | null): string {
  return value === null ? "—" : `${Math.round(value * 100)}%`;
}

function formatNumber(value: number): string {
  return Math.abs(value) >= 100 ? value.toFixed(1) : value.toFixed(3);
}
