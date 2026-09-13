# Hardware-transition acquisition contract (candidate, not deployed)

This candidate does not alter the running 161-test MATLAB baseline or the
dashboard. It fixes a gap in the earlier scalar-only MCU envelope: V2 includes
the *full inference inputs* (three scalar readings and uncertainties, spatial
observations, probe row/column and global heading). Ground truth and hidden
simulation diagnostic fields are excluded. Bearing-only observations are
encoded as `hasRange=false,range=0,rangeStd=0`, then restored to MATLAB's
NaN/Inf convention **after** JSON decoding. The wire JSON remains finite.

`acquireMeasurementV2(source, provider)` requires an explicit provider
function returning a V2 struct or JSON object; it validates and reconstructs
the usual MATLAB measurement fields. There is no fallback and a PROTEUS or
HARDWARE source cannot quietly masquerade as SIMULATION. A real hardware
source must supply measured pose, not a simulated pose. The same post-source
shape can feed `signalProcessingManager` without changing fusion code.

## To test without touching the demo

From the `matlab` current folder, after `addpath('Main'); setupProjectPaths`:

```matlab
results = runtests(fullfile(pwd,'Tests','testAcquisitionFrameV2.m'), ...
    'OutputDetail','Detailed');
disp(table(results))
```

## Not yet done — do not claim hardware readiness

- Mission-controller integration through this interface is intentionally
  withheld until MATLAB contract tests pass; the current mock ACK persists.
- A real serial provider needs chosen MCU firmware, framing, CRC, sequence
  tracking, timeouts and reconnect policy, and real sensor-specific drivers.
- Input range/bearing/noise/reliability need calibration against physical
  sensor outputs. Values are *not* made real by labelling the source HARDWARE.
- Spatial localization still depends on `scenario.environment` maps (e.g.
  debris/noise/obstacles/risk) and simulation grid position. Hardware requires
  measured probe pose and a surveyed or online-built environment map, plus
  validation with field-labelled cases independent of simulator ground truth.
- The UART/JSON layout may be too large for an 8-bit MCU with many targets.
  Benchmark wire size and select a supported MCU before freezing firmware.

Readiness claims: software-interface candidate only, not a Proteus link,
not proof of detection performance on buried persons, and not safe for
operational rescue decisions without rigorous external validation.
