# Integration Contract v1 — Candidate Fix 1

This candidate fixes only the new Integration layer. No detection, fusion,
localization, vitality, priority, rescue-planning, sensor, or evaluation-core
algorithm was changed.

Observed acceptance result before this fix:
- 145 Passed
- 2 Failed
- 0 Incomplete

The two failing tests were:
1. testPresetRejectsHiddenOverrides
2. testUnsupportedAccessibilityControlIsRejected

Root causes fixed:
- Preset custom fields were classified as UnknownField before the more precise
  PresetOverrideNotAllowed policy check.
- Error construction used string-array message syntax that can produce
  compatibility/identifier mismatches in MATLAB test expectations.

Expected after fix:
- all prior 145 passing tests remain passing;
- the two Integration policy tests pass;
- total expected: 147 Passed, 0 Failed, 0 Incomplete.

MATLAB execution remains the source of truth for acceptance.
