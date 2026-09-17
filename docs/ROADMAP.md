# USAR Smart Rescue System — Technical Roadmap

## 1. Purpose

This roadmap defines the major technical delivery stages of the
USAR Smart Rescue System.

It is intended to provide a clear relationship between project goals,
technical workstreams, deliverables, validation evidence, and future
development.

The roadmap represents major delivery stages rather than individual
development tasks.

---

## 2. Roadmap Principles

Project development follows the following principles:

- Each major capability must have a defined deliverable.
- Completion requires validation evidence, not implementation alone.
- Simulation results must remain separated from real-world performance claims.
- Changes to shared interfaces must be reviewed for downstream impact.
- AI development must use validated mission data and reproducible evaluation.
- Hardware integration must remain explicit and must not silently fall back to simulation.

---

## 3. Phase 1 — Core Mission Simulation

### Objective

Establish a reproducible simulation environment for collapsed-structure
search-and-rescue missions.

### Key Deliverables

- Scenario generation
- Victim placement
- Probe mission control
- Mission-state transitions
- Environmental condition modeling
- Random-seed support
- Ground-truth generation

### Status

Completed in the current simulation baseline.

### Completion Evidence

Mission execution and automated regression testing are available within
the MATLAB project.

---

## 4. Phase 2 — Multi-Sensor Intelligence

### Objective

Develop the sensing and information-processing pipeline required to
estimate victim presence under uncertain operating conditions.

### Key Deliverables

- UWB simulation
- Thermal simulation
- Acoustic simulation
- Signal processing
- Sensor-quality assessment
- Adaptive multi-sensor fusion
- Confidence estimation

### Status

Completed in the current simulation baseline and subject to continuing
validation.

---

## 5. Phase 3 — Localization and Victim Intelligence

### Objective

Convert fused sensor evidence into actionable victim intelligence.

### Key Deliverables

- Victim localization
- Candidate-location handling
- Victim database
- Repeated-detection association
- Vitality estimation
- Victim prioritization
- Confidence-aware decision support

### Status

Implemented with continuing validation and refinement.

---

## 6. Phase 4 — Mission Decision and Route Intelligence

### Objective

Support operational search and rescue decisions after victim detection.

### Key Deliverables

- Victim ranking
- Rescue-target selection
- Search-path logic
- Route recommendation
- Accessibility-aware decision support
- Mission-state updates

### Status

Implemented in the current system with continuing refinement.

---

## 7. Phase 5 — Backend and Operational Dashboard

### Objective

Expose mission intelligence through an operational interface suitable
for demonstration, monitoring, and decision support.

### Key Deliverables

- Backend mission interfaces
- Mission execution requests
- Health and status interfaces
- Mission result transport
- Operational map
- Victim cards
- Sensor and fusion intelligence
- Vitality information
- Rescue priority visualization
- Route visualization
- Scenario controls

### Status

Integrated in the current project baseline.

---

## 8. Phase 6 — Controlled Sensor Acquisition Boundary

### Objective

Create a stable acquisition interface that separates measurement
providers from the downstream inference system.

### Key Deliverables

- Acquisition Frame V2
- Acquisition-state management
- Frame validation
- Mission-local sequencing
- Explicit source selection
- Common acquisition interface
- Fail-closed handling for unavailable external providers

### Current Source

SIMULATION

### Future Declared Sources

- Proteus
- Hardware

### Status

Acquisition V2 architecture has been implemented for the simulation
path.

External Proteus or hardware providers must not be considered complete
until they are explicitly integrated and validated.

---

## 9. Phase 7 — AI Decision Intelligence

### Objective

Introduce a data-driven decision-intelligence layer while preserving
traceability and separation from simulation ground truth.

### Delivery Stages

```text
Validated Missions
        |
        v
Dataset Generation
        |
        v
Dataset Validation
        |
        v
Feature Engineering
        |
        v
Baseline Model
        |
        v
Model Training
        |
        v
Evaluation
        |
        v
Explainability
        |
        v
System Integration