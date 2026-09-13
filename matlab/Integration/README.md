# USAR Integration Contract v1

This layer wraps the frozen MATLAB core without changing detection, fusion, localization, vitality, priority, or rescue-planning algorithms.

## Supported Scenario Request v1

Effective dashboard inputs in MATLAB v4.1.4:

- `scenarioType`
- `randomSeed`
- `numVictims` (Custom only)
- `debrisDensity` (Custom only)
- `noiseLevel` (Custom only)
- `burialDepth` (Custom only)
- `vitalStrength` (Custom only)

`accessibility`, `riskLevel`, and `obstacleDensity` are intentionally not accepted as independent controls in Contract v1 because the current MATLAB core derives accessibility/risk/obstacles from generated environment maps.

## First test

```matlab
clear functions;
clear classes;
restoredefaultpath;
cd('PATH_TO_PROJECT_ROOT');
addpath(fullfile(pwd,'Main'),'-begin');
setupProjectPaths();

results = runAllTests();
assert(all([results.Passed]));
assert(~any([results.Incomplete]));
```

## Run one integration mission

```matlab
request = struct( ...
    'schemaVersion', "1.0", ...
    'scenarioType', "Custom", ...
    'randomSeed', 284, ...
    'numVictims', 5, ...
    'debrisDensity', 0.75, ...
    'noiseLevel', 0.60, ...
    'burialDepth', 0.80, ...
    'vitalStrength', 0.30);

[missionRun, finalProbe, scenario] = runScenarioRequest(request);
```

The mission is exported under:

```text
Outputs/missions/<MISSION_ID>/
  scenario.json
  result.json
  evaluation.json
```

- `scenario.json`: safe scenario summary; no victim ground-truth locations.
- `result.json`: operational result for the dashboard; no ground truth.
- `evaluation.json`: post-mission evaluation only; contains ground truth and metrics.

Telemetry/JSONL streaming is the next integration milestone.
\n\n## Live Telemetry v1\n\n`runScenarioRequest` now creates `telemetry.jsonl` before the mission starts.\nEach non-final mission-controller cycle appends one operational record containing:\n\n- mission ID and monotonic sequence\n- probe position/state/coverage\n- normalized and physical simulated sensor readings\n- observable sensor reliability only (no oracle diagnostics)\n- adaptive fusion score/confidence/weights\n- localization, vitality, priority, and decision state\n- newly confirmed victim summaries\n\nLifecycle records `MISSION_STARTED` and `MISSION_COMPLETED` are also written.\nGround Truth remains excluded from telemetry and is released only in `evaluation.json` after mission completion.\n