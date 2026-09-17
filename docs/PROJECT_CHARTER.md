# USAR Smart Rescue System — Project Charter

## 1. Project Overview

The USAR Smart Rescue System is a simulation-driven decision-support
platform designed to support Urban Search and Rescue operations in
collapsed structures.

The system combines multiple simulated sensing modalities with
localization, victim-condition estimation, prioritization, route
planning, and mission visualization to support more structured
search-and-rescue decisions under uncertainty.

---

## 2. Problem Statement

Search-and-rescue operations inside collapsed structures involve
significant uncertainty.

Victims may be deeply buried, sensor signals may be weak or noisy,
debris may affect measurements, and rescue teams may have limited
information about where to search first.

Relying on a single sensing modality may therefore lead to missed
detections, false alarms, or inefficient search decisions.

The project investigates how multiple imperfect sensing sources can be
combined to produce more reliable operational information.

---

## 3. Project Objective

The primary objective is to develop and validate a modular smart
search-and-rescue decision-support architecture capable of:

- simulating multi-sensor victim observations;
- combining UWB, thermal, and acoustic evidence;
- estimating victim location;
- estimating victim vitality;
- prioritizing detected victims;
- recommending search and rescue routes;
- presenting mission intelligence through an operational dashboard;
- supporting reproducible mission scenarios and validation.

---

## 4. Current Project Scope

The current project is a software and simulation-based system.

### In Scope

- Mission and collapsed-structure scenario simulation
- UWB sensing simulation
- Thermal sensing simulation
- Acoustic sensing simulation
- Signal processing
- Adaptive multi-sensor fusion
- Victim detection
- Victim localization
- Vitality estimation
- Victim prioritization
- Search-path and rescue-route recommendation
- Mission-state management
- Backend integration
- Operational dashboard
- Ground-truth comparison for simulation validation
- Reproducible random scenarios
- Automated testing and regression validation
- AI decision-intelligence development

### Out of Scope for the Current Release

- Certified real-world rescue deployment
- Clinical medical diagnosis
- Production rescue hardware
- Validated real-world UWB radar hardware integration
- Autonomous robotic rescue execution

Hardware and external acquisition sources may be integrated in future
versions through defined system interfaces.

---

## 5. Primary Stakeholders

The project is designed around the needs of:

- Urban Search and Rescue teams
- Emergency-response coordinators
- Rescue-operation decision makers
- Technical operators
- Researchers working on sensing and rescue intelligence
- Academic and innovation evaluators

---

## 6. Major System Components

The project currently contains three primary technical layers:

### MATLAB Intelligence and Simulation Layer

Responsible for:

- scenario generation;
- sensor simulation;
- signal processing;
- adaptive fusion;
- localization;
- vitality estimation;
- victim prioritization;
- route and mission logic;
- evaluation and validation.

### Backend Integration Layer

Responsible for providing the integration boundary between the
simulation/intelligence system and operational applications.

### Dashboard Layer

Responsible for presenting mission state, detected victims,
sensor intelligence, localization results, priorities, routes,
and decision-support information.

---

## 7. Key Deliverables

The project deliverables include:

- Executable rescue-mission simulation
- Multi-sensor fusion pipeline
- Victim localization capability
- Vitality and priority assessment
- Route recommendation
- Operational dashboard
- Scenario-generation capability
- Ground-truth validation
- Automated regression tests
- Technical documentation
- AI decision-intelligence layer
- Reproducible evaluation workflow

---

## 8. Project Constraints

Important project constraints include:

- Current validation is primarily simulation-based.
- Sensor behavior is represented through mathematical and simulation
  models rather than certified rescue hardware.
- Real-world performance cannot be inferred directly from simulation
  results without field validation.
- Hardware availability and integration may depend on external
  resources.
- Rescue decisions must remain interpretable and traceable.

---

## 9. Success Criteria

The project is considered technically successful when it demonstrates:

- stable mission execution;
- reproducible scenarios;
- reliable multi-sensor processing;
- measurable victim-detection performance;
- measurable localization performance;
- traceable victim-priority decisions;
- usable route recommendations;
- clear operational visualization;
- automated regression validation;
- documented limitations and assumptions.

Performance metrics may include:

- Precision
- Recall
- F1-score
- False-positive and false-negative counts
- Localization error
- Response time
- Mission success indicators

---

## 10. Delivery Principle

Project changes should follow a controlled delivery workflow:

Requirement
→ Defined Task
→ Acceptance Criteria
→ Implementation
→ Testing
→ Review
→ Acceptance
→ Release

Technical tasks should identify their deliverable, dependencies,
review requirements, and validation evidence before being considered
complete.

---

## 11. Current Development Direction

The current development direction focuses on strengthening the system
as an uncertainty-aware and traceable rescue decision-support
platform while maintaining a clear separation between:

- simulation evidence;
- AI-generated recommendations;
- ground-truth evaluation data;
- future real-world sensor inputs.

This separation is necessary to preserve technical integrity,
reproducibility, and trustworthy evaluation.