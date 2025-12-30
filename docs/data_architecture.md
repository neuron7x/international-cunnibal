# Data & AI Architecture Blueprint

This blueprint formalizes the on-device data and AI pipeline with data engineering hygiene: deterministic transforms, explicit contracts, and privacy-by-design.

## Goals
- **On-device only**: no PII leaves the device; exports are user-triggered.
- **Deterministic analytics**: repeatable metrics from identical inputs.
- **Stream-safe**: bounded buffers with backpressure and clamping.
- **Governed artifacts**: models and exports are versioned and auditable.

## Layered Pipeline
1. **Ingestion (edge)**  
   - Source: camera frames → `CvEngine` (demo or camera).  
   - Contract: normalized `TongueData` (timestamp, position, velocity, acceleration, landmarks, validation flag).  
   - Guardrails: permission gating, synthetic fallback when camera/models are absent.
2. **Processing (real-time)**  
   - `NeuralEngine` applies Action Acceptor validation and feeds `MotionMetrics`.  
   - Endurance path (opt-in): `EnduranceEngine` + `EnduranceGameLogicService` process aperture landmarks.  
   - Determinism: fixed buffer size (`NeuralEngineConstants.bufferSize`), clamped outputs, non-finite sanitization in `MotionMetrics`.
3. **State & Decisioning**  
   - `GameLogicService` and `EnduranceGameLogicService` consume metrics snapshots and emit level/target updates over streams.  
   - UI renders state only; no business logic in widgets.
4. **Persistence & Export**  
   - In-memory logs in `GitHubExportService` accumulate `BiometricMetrics` and `DictationSession`.  
   - Export: `ExportFileWriter` writes indented JSON to app storage with timestamped filenames; auto-export threshold guards runaway memory.
5. **Models & ML Assets**  
   - Tracked under `assets/models/` with README for integration.  
   - Versioning via filename/metadata; provenance captured in DVC-ready structure under `ml-ops/`.

## Data Contracts
- **TongueData**: normalized coordinates (0–1), velocity/acceleration in px/s, `isValidated` flag set by Action Acceptor.  
- **BiometricMetrics**: consistency (0–100), frequency (Hz + confidence), PCA variance ([pc1, pc2, 0]), movement direction, intensity, pattern score, optional endurance snapshot.  
- **DictationSession**: letter target, rhythm pattern, synchronization score (0–100), timestamps.

## Quality, Safety, and Observability
- **Idempotent start/stop** for engines; timers are cancellable and disposed.  
- **Privacy filters**: `LandmarkPrivacyFilter` zeroes facial landmarks before storage/export.  
- **Backpressure**: bounded buffers and auto-export thresholds prevent unbounded growth.  
- **Deterministic tests**: repeatable PCA, frequency, and consistency computations validated in `test/`.
- **Operational hooks**: `tool/ci/check_architecture_boundaries.py` prevents forbidden framework imports in domain layers.

## Deployment & Ops Guardrails
- **Offline-first**: all logic works without network; demo CV keeps UX functional.  
- **Permissions**: camera/storage requests in `main.dart`; tracking controls disabled until ready.  
- **Failure containment**: try/catch around camera init, graceful fallbacks to demo engine.  
- **Export safety**: user-triggered JSON only; filenames are timestamped to avoid collisions.
