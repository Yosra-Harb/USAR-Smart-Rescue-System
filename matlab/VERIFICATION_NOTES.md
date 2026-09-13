# Verification Notes

## Checks completed in the build workspace

- MATLAB block-balance scan over every `.m` file: no unmatched `end` found.
- Localization/Fusion/SignalProcessing scan: no executable reads of
  `scenario.victims`, `scenario.groundTruth`, or `environment.vitalSigns`.
  Those reads remain limited to SensorSimulation, Environment,
  Visualization/Evaluation, and tests.
- `Main/setupProjectPaths.m` includes the new `RescuePlanning` folder.
- v3 was not edited; v4 is a separate directory.

## Required verification in MATLAB

The build container does not contain a licensed MATLAB runtime, so the
following commands must be run after extraction:

```matlab
projectRoot = "C:\path\to\USAR_PhysicalFusion_v4_1_4_EmptySchemaFieldOrderFix";
cd(fullfile(projectRoot,"Main"));
setupProjectPaths;

acceptance = runMeasurementResolvedAcceptance;
```

This single gate runs 142 unit tests, targeted regressions, and 60 fresh
validation missions using seeds 4001:4010. It does not consume FinalTest.
Only after `acceptance.overallPassed == true`, run the frozen final split:

```matlab
[runs,scenarioSummary,splitSummary,raw] = ...
    runGeneralizationEvaluation([10 5 5]);
```

Do not tune thresholds after inspecting `FinalTest`.
