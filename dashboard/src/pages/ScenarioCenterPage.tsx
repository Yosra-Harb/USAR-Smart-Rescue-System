import { useEffect, useMemo, useState } from "react";

import {
  startScenario,
  type ScenarioRunRequest,
  type ScenarioRunStatus,
  type ScenarioType,
} from "../api/scenarioControlApi";

import ScenarioLaunchStatusBar from "../components/scenario/ScenarioLaunchStatusBar";
import { useScenarioRunStatus } from "../hooks/useScenarioRunStatus";

import "../styles/scenario-center.css";

type ScenarioMode = "fixed" | "generate";

type ScenarioCenterPageProps = {
  initialMode: ScenarioMode;
  onMissionStarted: () => void;
};

type CustomForm = {
  randomSeed: number;
  numVictims: number;
  debrisDensity: number;
  noiseLevel: number;
  burialDepth: number;
  vitalStrength: number;
};

const presets: Array<{
  type: Exclude<ScenarioType, "Custom">;
  title: string;
  subtitle: string;
  metrics: string;
}> = [
  {
    type: "Ideal",
    title: "Ideal",
    subtitle: "Baseline / low interference",
    metrics: "1 victim · debris 0.10 · noise 0.10",
  },
  {
    type: "DenseDebris",
    title: "Dense Debris",
    subtitle: "Heavy rubble environment",
    metrics: "1 victim · debris 0.80 · burial 0.60",
  },
  {
    type: "HighNoise",
    title: "High Noise",
    subtitle: "Acoustic/environment challenge",
    metrics: "1 victim · noise 0.80",
  },
  {
    type: "DeepBurial",
    title: "Deep Burial",
    subtitle: "Strong burial attenuation",
    metrics: "1 victim · burial 0.90 · debris 0.70",
  },
  {
    type: "MultipleVictims",
    title: "Multiple Victims",
    subtitle: "Multi-target mission",
    metrics: "5 victims · mixed conditions",
  },
  {
    type: "WeakVitalSigns",
    title: "Weak Vital Signs",
    subtitle: "Low vital evidence",
    metrics: "1 victim · vitality 0.25",
  },
];

const defaultCustom: CustomForm = {
  randomSeed: 731,
  numVictims: 3,
  debrisDensity: 0.5,
  noiseLevel: 0.4,
  burialDepth: 0.5,
  vitalStrength: 0.6,
};

export default function ScenarioCenterPage({
  initialMode,
  onMissionStarted,
}: ScenarioCenterPageProps) {
  const [mode, setMode] = useState<ScenarioMode>(initialMode);

  const [form, setForm] =
    useState<CustomForm>(defaultCustom);

  const [preview, setPreview] =
    useState<ScenarioRunRequest | null>(null);

  const [launch, setLaunch] =
    useState<ScenarioRunStatus | null>(null);

  const [error, setError] =
    useState<string | null>(null);

  const [busy, setBusy] = useState(false);

  /*
   * Real mission state from the backend.
   *
   * This prevents the dashboard from relying only on the local
   * launch request state.
   */
  const run = useScenarioRunStatus(900);

  const missionActive =
    run?.status === "STARTING_MATLAB" ||
    run?.status === "RUNNING";

  /*
   * Lock mission controls while:
   *
   * 1. the launch request is being submitted, or
   * 2. MATLAB is starting, or
   * 3. a mission is actively running.
   */
  const controlsLocked = busy || missionActive;

  /*
   * Once the backend confirms that the mission has progressed beyond
   * the local launch phase, the backend status becomes the source
   * of truth and the local busy flag can be cleared.
   */
  useEffect(() => {
    if (!busy) {
      return;
    }

    if (
      run?.status === "RUNNING" ||
      run?.status === "COMPLETED" ||
      run?.status === "FAILED"
    ) {
      setBusy(false);
    }
  }, [busy, run?.status]);

  const customRequest = useMemo<ScenarioRunRequest>(
    () => ({
      schemaVersion: "1.0",
      scenarioType: "Custom",
      randomSeed: form.randomSeed,
      numVictims: form.numVictims,
      debrisDensity: form.debrisDensity,
      noiseLevel: form.noiseLevel,
      burialDepth: form.burialDepth,
      vitalStrength: form.vitalStrength,
    }),
    [form],
  );

  async function launchRequest(
    request: ScenarioRunRequest,
  ): Promise<void> {
    /*
     * Guard against double-clicks and against starting another
     * mission while MATLAB is already busy.
     */
    if (controlsLocked) {
      return;
    }

    setBusy(true);
    setError(null);
    setLaunch(null);

    try {
      const next = await startScenario(request);

      setLaunch(next);

      /*
       * Mission Operations takes over shortly after the backend
       * accepts the request.
       */
      window.setTimeout(() => {
        onMissionStarted();
      }, 450);
    } catch (launchError: unknown) {
      setError(
        launchError instanceof Error
          ? launchError.message
          : "Scenario launch failed.",
      );

      setBusy(false);
    }
  }

  return (
    <section className="scenario-center">
      <div className="scenario-center__hero">
        <div>
          <span className="scenario-center__eyebrow">
            MISSION CONTROL
          </span>

          <h2>Scenario Center</h2>

          <p>
            Start MATLAB missions directly from the dashboard.
            Fixed runs use the project presets; generated scenarios
            use only effective Contract v1 controls.
          </p>
        </div>

        <div className="scenario-center__tabs">
          <button
            type="button"
            className={
              mode === "fixed"
                ? "is-active"
                : ""
            }
            disabled={controlsLocked}
            onClick={() => setMode("fixed")}
          >
            Fixed Runs
          </button>

          <button
            type="button"
            className={
              mode === "generate"
                ? "is-active"
                : ""
            }
            disabled={controlsLocked}
            onClick={() => setMode("generate")}
          >
            Generate Scenario
          </button>
        </div>
      </div>

      <ScenarioLaunchStatusBar />

      {error && (
        <div className="scenario-error">
          {error}
        </div>
      )}

      {launch && (
        <div className="scenario-accepted">
          Request accepted:{" "}
          <strong>{launch.runId}</strong>.
          {" "}Opening Mission Operations...
        </div>
      )}

      {mode === "fixed" ? (
        <div className="scenario-preset-grid">
          {presets.map((preset) => (
            <article
              className="scenario-card"
              key={preset.type}
            >
              <div className="scenario-card__icon">
                ◆
              </div>

              <h3>{preset.title}</h3>

              <p>{preset.subtitle}</p>

              <span>{preset.metrics}</span>

              <button
                type="button"
                disabled={controlsLocked}
                onClick={() =>
                  void launchRequest({
                    schemaVersion: "1.0",
                    scenarioType: preset.type,
                  })
                }
              >
                {missionActive
                  ? "Mission Running"
                  : busy
                    ? "Starting MATLAB..."
                    : "Run Fixed Scenario"}
              </button>
            </article>
          ))}
        </div>
      ) : (
        <div className="scenario-generator-layout">
          <form
            className="scenario-generator"
            onSubmit={(event) => {
              event.preventDefault();

              if (controlsLocked) {
                return;
              }

              setPreview(customRequest);
              setError(null);
            }}
          >
            <h3>
              Custom Scenario Generator
            </h3>

            <p className="scenario-generator__note">
              Accessibility, risk and obstacle density remain
              MATLAB-generated environment properties in Contract v1;
              they are intentionally not exposed as fake controls.
            </p>

            <NumberField
              label="Random Seed"
              value={form.randomSeed}
              min={0}
              max={4294967295}
              step={1}
              disabled={controlsLocked}
              onChange={(value) =>
                setForm((current) => ({
                  ...current,
                  randomSeed: value,
                }))
              }
            />

            <NumberField
              label="Number of Victims"
              value={form.numVictims}
              min={1}
              max={20}
              step={1}
              disabled={controlsLocked}
              onChange={(value) =>
                setForm((current) => ({
                  ...current,
                  numVictims: value,
                }))
              }
            />

            <RangeField
              label="Debris Density"
              value={form.debrisDensity}
              disabled={controlsLocked}
              onChange={(value) =>
                setForm((current) => ({
                  ...current,
                  debrisDensity: value,
                }))
              }
            />

            <RangeField
              label="Noise Level"
              value={form.noiseLevel}
              disabled={controlsLocked}
              onChange={(value) =>
                setForm((current) => ({
                  ...current,
                  noiseLevel: value,
                }))
              }
            />

            <RangeField
              label="Burial Depth"
              value={form.burialDepth}
              disabled={controlsLocked}
              onChange={(value) =>
                setForm((current) => ({
                  ...current,
                  burialDepth: value,
                }))
              }
            />

            <RangeField
              label="Vital Strength"
              value={form.vitalStrength}
              disabled={controlsLocked}
              onChange={(value) =>
                setForm((current) => ({
                  ...current,
                  vitalStrength: value,
                }))
              }
            />

            <button
              className="scenario-generator__generate"
              type="submit"
              disabled={controlsLocked}
            >
              {missionActive
                ? "Mission Running"
                : "Generate Scenario"}
            </button>
          </form>

          <aside className="scenario-preview">
            <span className="scenario-center__eyebrow">
              PRE-RUN PREVIEW
            </span>

            <h3>
              {preview
                ? "Scenario Ready"
                : "Generate a scenario first"}
            </h3>

            {preview ? (
              <>
                <dl>
                  <PreviewRow
                    label="Seed"
                    value={preview.randomSeed}
                  />

                  <PreviewRow
                    label="Victims"
                    value={preview.numVictims}
                  />

                  <PreviewRow
                    label="Debris"
                    value={preview.debrisDensity}
                  />

                  <PreviewRow
                    label="Noise"
                    value={preview.noiseLevel}
                  />

                  <PreviewRow
                    label="Burial"
                    value={preview.burialDepth}
                  />

                  <PreviewRow
                    label="Vital Strength"
                    value={preview.vitalStrength}
                  />

                  <PreviewRow
                    label="Grid"
                    value="50 × 50"
                  />
                </dl>

                <p>
                  The spatial debris, obstacle, accessibility, risk and
                  victim maps are generated by MATLAB when the mission
                  starts. Ground truth remains hidden operationally.
                </p>

                <button
                  type="button"
                  disabled={controlsLocked}
                  onClick={() =>
                    void launchRequest(preview)
                  }
                >
                  {missionActive
                    ? "Mission Running"
                    : busy
                      ? "Starting MATLAB..."
                      : "Start Generated Mission"}
                </button>
              </>
            ) : (
              <p>
                Adjust the effective controls, then press Generate
                Scenario to review the exact request before MATLAB
                execution.
              </p>
            )}
          </aside>
        </div>
      )}
    </section>
  );
}

function RangeField({
  label,
  value,
  onChange,
  disabled = false,
}: {
  label: string;
  value: number;
  onChange: (value: number) => void;
  disabled?: boolean;
}) {
  return (
    <label className="scenario-field scenario-field--range">
      <span>{label}</span>

      <strong>
        {value.toFixed(2)}
      </strong>

      <input
        type="range"
        min="0"
        max="1"
        step="0.01"
        value={value}
        disabled={disabled}
        onChange={(event) =>
          onChange(
            Number(event.target.value),
          )
        }
      />
    </label>
  );
}

function NumberField({
  label,
  value,
  min,
  max,
  step,
  onChange,
  disabled = false,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  onChange: (value: number) => void;
  disabled?: boolean;
}) {
  return (
    <label className="scenario-field">
      <span>{label}</span>

      <input
        type="number"
        value={value}
        min={min}
        max={max}
        step={step}
        disabled={disabled}
        onChange={(event) =>
          onChange(
            Number(event.target.value),
          )
        }
      />
    </label>
  );
}

function PreviewRow({
  label,
  value,
}: {
  label: string;
  value:
    | string
    | number
    | null
    | undefined;
}) {
  return (
    <>
      <dt>{label}</dt>

      <dd>
        {value === null ||
        value === undefined
          ? "—"
          : typeof value === "number"
            ? Number.isInteger(value)
              ? value
              : value.toFixed(2)
            : value}
      </dd>
    </>
  );
}