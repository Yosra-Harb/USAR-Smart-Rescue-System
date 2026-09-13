# Live Telemetry v1.1 — FIX1

This patch changes telemetry integration only. Detection, sensor simulation,
fusion, localization, vitality, priority and rescue-planning equations are unchanged.

## Fix 1 — UTC timestamp correctness
Runtime STEP records previously reused an unzoned measurement timestamp and then
assigned UTC to it. On a UTC+03 workstation this produced STEP timestamps about
three hours ahead of MISSION_STARTED / MISSION_COMPLETED. Runtime and lifecycle
records now use a single UTC export clock (`telemetryTimestampUtc`).

## Fix 2 — provisional track semantics
A new internal victim-database ID is not a final confirmed victim. The event name
`VICTIM_CONFIRMED` was therefore misleading when transient tracks were later merged
or consolidated. Telemetry schema v1.1 now emits `VICTIM_TRACK_CREATED`, exposes
`activeTrackCount`, and uses `newTracks`. Final confirmed victims remain authoritative
in `result.json` / the MISSION_COMPLETED final result contract.
