# End-to-End Delivery Plan (Repo → Store-Ready Release)

> Purpose: This document turns the current repository state into a **production-grade, store-ready app** with reproducible builds, privacy-first guarantees, and operational readiness. It is intended to be **actionable** for engineers and PR agents: it explains **what** we are building, **why**, **how**, and **what “done” means**.

---

## 0) Product intent (core truth)

- **What**: A privacy-first, on-device training app that analyzes motion patterns in real time and presents deterministic metrics, session progress, and feedback.
- **Why**: Provide structured training with neutral, non-medical feedback, and consistent, testable metrics without collecting or storing raw video.
- **How**: On-device CV + metrics engine, deterministic tests, consent-first UX, and strict CI gates.
- **Hard constraints**:
  - **No raw video storage**
  - **No medical claims**
  - **Privacy-by-design**
  - **Deterministic metrics** (no NaN/Inf, bounded outputs)

---

## 1) Current State Inventory (extracted from repo)

### 1.1 Screens & Features
- **Home**: Feature hub navigation (`lib/screens/home_screen.dart`)
- **Bio-Tracking**: camera/demo CV feed + overlay, start/stop (`lib/screens/tracking_screen.dart`)
- **Symbol Dictation**: A–Z rhythmic synchronization (`lib/screens/dictation_screen.dart`)
- **Partner Mode**: custom partner rhythm input, consent copy (`lib/screens/partner_mode_screen.dart`)
- **Endurance Mode**: opt-in session flow (demo), stability/score (`lib/screens/endurance_mode_screen.dart`)
- **Metrics Dashboard**: live metrics + export (`lib/screens/metrics_screen.dart`)

### 1.2 Core Logic / Domain
- **MotionMetrics**: direction, consistency, intensity, frequency, pattern match (`lib/core/motion_metrics.dart`)
- **EnduranceMetrics**: aperture stability, fatigue, endurance score (`lib/core/endurance_metrics.dart`)
- **NeuralEngine**: metrics pipeline + stream (`lib/services/neural_engine.dart`)
- **CV Engine**: demo/camera modes (`lib/services/cv_engine.dart`)
- **Game logic**: scoring and leveling (`lib/services/game_logic_service.dart`, `lib/services/endurance_game_logic_service.dart`)

### 1.3 CI / Workflows / Required Checks
- **Flutter CI** (format/analyze/test/coverage + guards)
- **Docs/Intent Guard** (docs changes required for core changes)
- **Dependency Review** (fail on high)
- **Secret Scan (gitleaks)**
- **CodeQL** (placeholder buildless scan)
- **CI Meta Guard** (action version guard)

See `.github/workflows/*.yml` and `SECURITY_PIPELINE.md`.

### 1.4 Tests (coverage focus)
- Metrics tests: `test/motion_metrics_test.dart`, `test/endurance_metrics_test.dart`
- CV/engine lifecycle: `test/cv_engine_test.dart`, `test/demo_cv_engine_test.dart`
- Game logic: `test/game_logic_service_test.dart`
- Dictation: `test/symbol_dictation_test.dart`
- Export: `test/github_export_service_test.dart`
- Privacy: `test/landmark_privacy_test.dart`
- UI gating: `test/tracking_screen_logic_test.dart`

### 1.5 Dependencies & Policy Risks
- **Camera access** via `camera`, **permissions** via `permission_handler`
- **On-device ML** via `tflite_flutter`
- **Policy risks**: adult-content adjacencies → must keep **neutral language**, **age gating**, **consent-first UX**, and **no medical claims**.

---

## 2) Phase-by-Phase Plan (with PR order)

> Each phase contains Goal, Deliverables, PRs, DoD, Risks/Mitigations.

### PHASE 0 — Baseline & Hard Gates (Merge-Safe Repo)
**Goal**: The repo becomes a reliable factory.

**Deliverables**
- Branch protection requirements documented and accurate
- Issue templates added
- CI gates align with `SECURITY_PIPELINE.md`

**PRs (in order)**
1. **PR-0.1**: Add issue templates + confirm required checks list
2. **PR-0.2**: Repository policy pack (branch protection + CODEOWNERS alignment)

**DoD**
- Required checks list reflects actual workflows
- Merge blocked when any check fails
- `SECURITY_PIPELINE.md` matches reality

**Risks & Mitigations**
- **Risk**: docs drift from real checks → **Mitigation**: enforce doc updates in PR-0.1

---

### PHASE 1 — Product Core Engine (Metrics-first, determinism)
**Goal**: The app’s “truth layer” is stable and deterministic.

**Deliverables**
- `docs/metrics.md` updated to be the single source of truth
- Golden synthetic signals test suite (sine/circle/jitter/constant/ramp)
- FPS invariance tests for motion metrics
- Coverage threshold justified

**PRs (in order)**
1. **PR-1.1**: Metrics constitution consolidation (`docs/metrics.md`)
2. **PR-1.2**: Golden signals + invariance tests
3. **PR-1.3**: Coverage policy justification

**DoD**
- All metric unit/regression tests green
- No NaN/Inf possible (verified)
- Coverage threshold enforced

**Risks & Mitigations**
- **Risk**: logic mismatch between metrics + UI → **Mitigation**: single source of truth + tests

---

### PHASE 2 — CV Runtime & Device Robustness
**Goal**: Camera → CV → metrics pipeline stable on-device.

**Deliverables**
- CV adapter contract with clean interface
- Demo + real camera share the same pipeline
- Backpressure strategy validated
- Thermal/battery-safe sampling strategy
- Performance benchmark harness

**PRs (in order)**
1. **PR-2.1**: CV adapter contract + backpressure
2. **PR-2.2**: Unified pipeline + “no frame storage” enforcement
3. **PR-2.3**: Benchmark harness and budgets

**DoD**
- Integration tests: mock camera → metrics → UI
- Bench budgets defined and enforced
- “No frame storage” verified (code + tests)

**Risks & Mitigations**
- **Risk**: implicit frame storage → **Mitigation**: explicit guard + tests
- **Risk**: thermal/battery drain → **Mitigation**: adaptive sampling

---

### PHASE 3 — Game Loop (Levels, sessions, rewards)
**Goal**: App behaves as a complete training product.

**Deliverables**
- Session FSMs (motion + endurance)
- 7 levels or scalable MVP design
- Neutral feedback messaging
- Local progress persistence

**PRs (in order)**
1. **PR-3.1**: Session FSM core + persistence
2. **PR-3.2**: Leveling + feedback system
3. **PR-3.3**: Widget tests for core flows

**DoD**
- Start → run → summary → save widget tests
- Deterministic scoring for same inputs
- Clear domain vs UI separation

**Risks & Mitigations**
- **Risk**: nondeterministic scoring → **Mitigation**: deterministic test inputs

---

### PHASE 4 — Couple & Partner Features (Optional Differentiator)
**Goal**: Partner/couple features, consent-first and non-coercive.

**Deliverables**
- Couple dashboard model + UI (opt-in)
- Explicit consent to compare (off by default)
- Partner pattern composer + matcher

**PRs (in order)**
1. **PR-4.1**: Consent gating + UX copy
2. **PR-4.2**: Matcher correctness + tolerances tests

**DoD**
- Matcher correctness tests
- UX copy reviewed for safety/consent

**Risks & Mitigations**
- **Risk**: policy rejection due to adult-adjacent wording → **Mitigation**: neutral language + age gating (Phase 7)

---

### PHASE 5 — Data & Privacy (Local-first)
**Goal**: Privacy-by-design with portability.

**Deliverables**
- Local storage schema + migrations
- Export/import JSON flow
- Optional Firebase sync behind a flag (if ever used)
- Privacy policy + Terms + consent screen

**PRs (in order)**
1. **PR-5.1**: Local storage + migrations
2. **PR-5.2**: Export/import UX + docs
3. **PR-5.3**: Privacy policy + consent screen

**DoD**
- Airplane mode works
- “No video stored” guaranteed by architecture
- Security review checklist complete

**Risks & Mitigations**
- **Risk**: accidental PII or media retention → **Mitigation**: explicit data schema + tests

---

### PHASE 6 — Observability & Quality
**Goal**: Ship without flying blind.

**Deliverables**
- Crash reporting (privacy-safe)
- Perf traces (startup, frame drops)
- Analytics minimal events (opt-in)
- Triage + rollback docs

**PRs (in order)**
1. **PR-6.1**: Crash + perf instrumentation
2. **PR-6.2**: Analytics opt-in + redaction
3. **PR-6.3**: Ops docs (triage, rollback)

**DoD**
- crash-free > 99.5% target defined
- P0/P1 triage rules documented
- rollback plan in docs

**Risks & Mitigations**
- **Risk**: sensitive payloads → **Mitigation**: event scrubbing + opt-in

---

### PHASE 7 — Store Readiness
**Goal**: Store submission ready.

**Deliverables**
- App icon, screenshots, store copy (neutral)
- Age gating
- Policy compliance review
- Signing, versioning, release channels
- Reproducible release builds

**PRs (in order)**
1. **PR-7.1**: Store assets + copy
2. **PR-7.2**: Age gating + compliance review
3. **PR-7.3**: Signing + CI release artifacts

**DoD**
- reproducible builds in CI
- staged rollout checklist
- go/no-go gates formalized

**Risks & Mitigations**
- **Risk**: store rejection → **Mitigation**: neutral copy, age gating, consent-first UX

---

### PHASE 8 — Launch & Post-Launch
**Goal**: Scale safely.

**Deliverables**
- Feedback loop
- Incident response playbook
- v1.1/v1.2 roadmap

**PRs (in order)**
1. **PR-8.1**: Feedback + roadmap docs
2. **PR-8.2**: Incident response playbook

**DoD**
- Weekly release cadence feasible
- Regression suite prevents metric drift

---

## 3) Required Artifacts (must exist before release)
- `docs/metrics.md` (formulas, invariants, ranges)
- `docs/privacy.md`, `docs/terms.md`, `docs/security_review.md`
- Benchmarks: CV loop + metrics compute budgets
- “No video storage” tests and architectural proof
- CI coverage reports and thresholds
- Release artifacts: signed builds + checksums

---

## 4) Release Checklist (step-by-step)
1. **All CI green** (Flutter CI, CodeQL, Dependency Review, Secret Scan, Docs Guard)
2. **Metrics constitution** and regression suite passing
3. **Privacy**: consent screen + policies + data-flow verification
4. **No raw video storage** verified by tests and architecture
5. **Performance budgets** met on mid-tier device profile
6. **Crash-free target** defined and baseline measured in beta
7. **Store assets + copy** ready and policy reviewed
8. **Signed build** generated via CI
9. **Go/No-Go review** completed

---

## 5) Go/No-Go Gates (hard blockers)
- All CI checks green + branch protected
- Metrics contract complete + regression suite passing
- Privacy policy + consent screen implemented
- No raw video storage confirmed
- Crash-free baseline in beta
- Performance budgets met on mid device profile
- App store language compliant

---

## 6) PR Agent Guidance (how to contribute safely)
- **Never relax tests or fake CI results**.
- **If metrics logic changes**, update metric tests and `docs/metrics.md`.
- **If core/service/model code changes**, update architecture docs.
- **No video storage** is a hard invariant.
- **Use neutral, non-medical language** in UX and store copy.

---

## 7) Source of Truth Links
- Architecture: `docs/architecture.md`
- Metrics contracts: `docs/metrics.md`
- Security pipeline: `SECURITY_PIPELINE.md`
- CI workflows: `.github/workflows/*.yml`
