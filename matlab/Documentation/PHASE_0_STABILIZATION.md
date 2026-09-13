# Phase 0 — Baseline Stabilization

## Purpose

This phase makes the current MATLAB prototype deterministic and auditable before
changing the adaptive-fusion or localization mathematics. Threshold values were
centralized without tuning them, so later experiments can measure algorithmic
changes against the same baseline.

## Problems confirmed in the uploaded baseline

- 116 MATLAB files, including 28 zero-byte placeholders.
- Seven duplicated MATLAB filenames.
- One invalid ZIP entry whose filename contained an entire MATLAB function.
- Hidden cross-run state in `victimClustering` through `persistent pointHistory`.
- `moveProbe` ignored the generated local-search path.
- Decision labels did not match `probeStateMachine` labels.
- A single detection could match more than one ground-truth victim during
  evaluation.
- Thresholds were duplicated across candidate detection, decision making,
  adaptive search, database association, evaluation, and reporting.

## Stabilization changes

- `Utilities/constants.m` is the single source for baseline thresholds.
- `Utilities/logger.m` gates debug messages; normal simulation output remains.
- `Main/setupProjectPaths.m` adds only approved runtime folders.
- Temporal localization history now lives in
  `probe.memory.localizationState`, so a new probe starts with clean state.
- Local-search movement now takes precedence over the coverage path and an
  unfinished local path is no longer regenerated every cycle.
- Evaluation uses one-to-one detection/ground-truth matching.
- Empty and obsolete duplicate files are deleted or preserved under `Legacy`
  with a non-executable `.disabled` suffix.
- `Tests/testPhase0Stabilization.m` protects the stabilized behavior.

## Run the regression tests in MATLAB Online

1. Open the `USAR_Project` project.
2. Open `Tests/runPhase0Tests.m`.
3. Press **Run**.
4. Do not continue to the fusion/localization redesign unless every test passes.

Equivalent Command Window invocation:

```matlab
addpath("Tests")
results = runPhase0Tests();
```

## Scientific limitations intentionally not hidden by Phase 0

Phase 0 does not claim that the current algorithm is accurate. The active
localizer still estimates a victim from probe-position samples using an
unweighted centroid. The adaptive-weight calculation also multiplies all sensor
reliabilities by the same agreement scalar, which cancels during normalization.
These are Phase 1 algorithmic defects and must be replaced by an evidence-map,
peak-detection, weighted-centroid, and temporal-tracking pipeline before final
experiments or publication claims.
