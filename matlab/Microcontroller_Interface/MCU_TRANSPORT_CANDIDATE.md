# MCU transport candidate — offline preparation

This is **not a live Proteus connection**. The existing `sensorManager` and
`communicationManager` remain unchanged; production missions still use the
old in-process mock ACK. Never describe that ACK as coming from a device.

## Candidate wire contract

- One UTF-8 JSON object per line, protocol version `1.0`.
- MATLAB simulation supplies `missionId`, nonnegative integer `sequence`, UTC
  timestamp, probe pose, and the three observed sensor readings. Each reading
  carries normalized value, physical proxy, unit, and observable reliability.
- Only these explicitly whitelisted fields are sent. Ground truth, hidden
  simulation reliability, diagnostic oracle fields, fusion, and victim ranks
  stay out of the acquisition transport.
- The software MCU checks the frame, its sequence against the **caller's**
  last accepted sequence, and echoes the three readings with mission ID,
  sequence, `ACK`, and `VALID`. MATLAB rejects missing/altered responses.
- Reset the caller's sequence state for each mission. Do not treat this
  software emulator as evidence that Proteus UART works or that a hardware
  sensor has been calibrated.

## Scope and next gate

Run in MATLAB Desktop from `matlab` after `setupProjectPaths`:

```matlab
results = runtests('testMCUTransportContract');
disp(table(results))
```

Then run `runAllTests` to check unchanged mission behavior. The next gate is
an available, licensed Proteus VSM installation and a selected MCU/serial
bridge; only then implement UART firmware, timeouts and checksum/CRC, an
actual serial adapter, and explicit mission opt-in. The current echo check is
an offline contract test, **not** an adequate wire integrity code. Actual
hardware also needs calibrated sensor drivers and real pose/time sources;
replacing the simulation signal source alone does not make the full system
field-ready.
