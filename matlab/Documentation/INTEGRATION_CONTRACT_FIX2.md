# Integration Contract v1 — Candidate Fix 2

Observed first end-to-end custom mission (seed 284) completed successfully with:
- 5 detections, TP=5, FP=0, FN=0, F1=1.0
- mean localization error about 0.4828 cells
- all three JSON contracts generated and decoded successfully

However, the operational output exposed duplicate victim ID `12` for two distinct
final positions. Detection/localization evaluation remained correct because it uses
positions, not IDs, but duplicate IDs are unsafe for Dashboard/Proteus identity,
rescue-plan mapping, event updates, and future telemetry.

Root cause:
`updateVictimDatabase.m` allocated a new ID as `length(detectedVictims)+1`.
Because duplicate merging can delete a record while preserving older IDs, the
remaining IDs can contain gaps (for example `[1 3]`). The old allocator would then
assign `3` again.

Fix 2:
1. Allocate new IDs as `max(existingIDs)+1`.
2. Fail fast if an incoming/current victim database already contains duplicate or
   invalid IDs.
3. Rescue planning validates ID uniqueness before ID-based reordering.
4. Integration export validates ID uniqueness before emitting operational JSON.
5. Add two regression tests: ID allocation after a merge gap and contract rejection
   of duplicate IDs.

Expected test total after Fix 2: 149 Passed, 0 Failed, 0 Incomplete.
MATLAB execution remains the acceptance source of truth.
