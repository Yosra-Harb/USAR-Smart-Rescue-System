# USAR Smart Rescue System — System Architecture

## 1. Purpose

This document describes the high-level technical architecture of the
USAR Smart Rescue System and the responsibilities and dependencies of
its major components.

The architecture is designed to separate:

- sensing and data acquisition;
- signal processing;
- sensor fusion;
- victim localization;
- vitality assessment;
- operational decision logic;
- AI decision intelligence;
- backend integration;
- dashboard visualization;
- validation and ground-truth evaluation.

This separation supports modular development, testing, traceability,
and future replacement of individual components.

---

## 2. High-Level Architecture

```text
Mission / Scenario Configuration
              |
              v
      Scenario Generator
              |
              v
      Probe Mission Controller
              |
              v
      Acquisition Boundary
              |
       +------+------+
       |             |
       v             v
 Simulation      Future External
 Sensors         Sensor Providers
                 (Proteus / Hardware)
       |
       v
 Signal Processing
       |
       v
 Adaptive Multi-Sensor Fusion
       |
       v
 Localization
       |
       v
 Vitality Estimation
       |
       v
 Victim Prioritization
       |
       v
 Decision / Route Logic
       |
       +-------------------+
       |                   |
       v                   v
 AI Decision          Mission / Victim
 Intelligence         State Management
       |                   |
       +---------+---------+
                 |
                 v
        Backend Integration
                 |
                 v
       Operational Dashboard
                 |
                 v
     Rescue Decision Support