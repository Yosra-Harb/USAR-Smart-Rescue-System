# USAR Smart Rescue System — Risk Register

## 1. Purpose

This document identifies major technical and delivery risks that may
affect the USAR Smart Rescue System.

The objective is to make risks visible, assign mitigation actions,
and support informed delivery decisions.

---

## 2. Risk Rating

Risks are evaluated using:

- Probability: Low / Medium / High
- Impact: Low / Medium / High

Priority should increase when both probability and impact are high.

---

## 3. Current Risk Register

| ID | Risk | Probability | Impact | Mitigation | Status |
|---|---|---|---|---|---|
| R1 | Simulation results may not represent real collapsed-structure conditions accurately | High | High | Clearly separate simulation validation from real-world claims; plan future field validation | Open |
| R2 | Ground-truth data could accidentally leak into operational inference | Medium | High | Maintain strict separation between ground truth and inference pipeline; include regression tests | Controlled |
| R3 | Localization accuracy may degrade in dense debris or weak-signal scenarios | Medium | High | Compare localization methods; run scenario-based evaluation; track localization error | Open |
| R4 | Sensor fusion may over-rely on one sensor under abnormal conditions | Medium | High | Use adaptive weighting, quality estimation, and agreement checks | Controlled |
| R5 | External Proteus or hardware provider is not yet integrated | High | Medium | Fail closed when unavailable; keep simulation source explicit; treat hardware integration as separate milestone | Open |
| R6 | AI model may learn simulation-specific patterns and fail to generalize | Medium | High | Validate datasets, avoid leakage, use baseline comparisons, test across diverse scenarios | Open |
| R7 | AI model performance may appear strong because of limited or biased scenarios | Medium | High | Expand evaluation set, preserve random seeds, evaluate difficult scenarios separately | Open |
| R8 | Backend contract changes may break dashboard integration | Medium | Medium | Version interfaces; document contracts; run integration tests before merge | Open |
| R9 | MATLAB interface changes may affect backend mission execution | Medium | High | Treat interface changes as controlled architecture changes and run end-to-end tests | Open |
| R10 | Route recommendations may be technically valid but operationally unrealistic | Medium | Medium | Validate routes against accessibility assumptions and scenario constraints | Open |
| R11 | Large generated mission-output files may clutter the Git repository | High | Medium | Exclude transient runtime outputs through `.gitignore`; preserve only selected validation evidence | Open |
| R12 | Permission issues may prevent Git from reading some dashboard directories | Medium | Medium | Investigate folder permissions before release; verify repository completeness | Open |
| R13 | Scope expansion may delay hackathon readiness | High | High | Freeze hackathon scope; move non-essential features to future roadmap | Controlled |
| R14 | Documentation may drift from actual implementation | Medium | Medium | Update documentation during Pull Request review and release preparation | Open |
| R15 | Regression changes may be missed if only targeted tests are executed | Medium | High | Require full regression verification before release | Controlled |

---

## 4. High-Priority Risks

The following risks require the highest attention:

### R1 — Simulation-to-Reality Gap

Current system validation is simulation-based.

The project must not claim certified field performance until real-world
sensor and operational validation are completed.

### R2 — Ground-Truth Leakage

Simulation ground truth is required for evaluation but must never be
used as hidden operational input.

Controls include:

- separate data paths;
- explicit evaluation-only fields;
- automated regression tests;
- review of integration boundaries.

### R6 — AI Generalization

AI performance must not be evaluated only on data closely resembling
training scenarios.

Mitigation requires:

- varied scenario generation;
- reproducible test sets;
- difficult-condition evaluation;
- baseline comparison;
- leakage checks.

### R13 — Scope Expansion

New capabilities can delay a stable hackathon release.

The active hackathon scope should prioritize:

- stable mission execution;
- victim detection;
- localization;
- prioritization;
- route display;
- dashboard;
- reproducibility;
- validated AI development milestones.

Non-critical features should be moved to future roadmap stages.

---

## 5. Risk Handling Workflow

When a new risk is identified:

```text
Identify Risk
      |
      v
Assess Probability
      |
      v
Assess Impact
      |
      v
Define Mitigation
      |
      v
Assign Owner
      |
      v
Track Status
      |
      v
Review During Delivery