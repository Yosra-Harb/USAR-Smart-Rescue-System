# Legacy files

This folder preserves files removed from the active MATLAB execution path during
Phase 0 stabilization.

- `EmptyPlaceholders` contains zero-byte scaffolding files that were not part of
  the implemented pipeline.
- `ObsoleteDuplicates` contains older functions whose names collided with the
  active implementation.
- `ObsoleteDashboard` is reserved for the retired App Designer dashboard; the
  project now uses the React dashboard.

The `.disabled` suffix prevents MATLAB from treating these files as executable
functions. They must not be added back to the MATLAB path without a deliberate
review and unique function names.
