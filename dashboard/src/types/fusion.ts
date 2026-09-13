export interface MissionSensorReading {
  normalized: number | null;
  physical: number | null;
  unit: string;
  reliability: number | null;
}

export interface MissionSensors {
  quality: number | null;
  radar: MissionSensorReading;
  thermal: MissionSensorReading;
  acoustic: MissionSensorReading;
}

export interface MissionFusion {
  score: number | null;
  confidence: number | null;
  weights: {
    radar: number | null;
    thermal: number | null;
    acoustic: number | null;
  };
}
