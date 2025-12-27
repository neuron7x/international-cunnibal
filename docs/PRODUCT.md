# Product Overview

## What the user experiences
International Cunnibal guides rhythmic training sessions and surfaces live
feedback on motion quality. The user sees:

- A real-time session screen with motion metrics (consistency, frequency,
  direction stability, intensity).
- Clear feedback when they match the target tempo or cadence.
- Session summaries suitable for sharing or exporting.

## What happens under the hood

- **Motion sampling**: normalized 2D positions are captured and buffered.
- **Metrics engine**: `MotionMetrics.compute` derives deterministic scores for
  consistency, frequency, direction, and intensity (see `docs/METRICS.md`).
- **Game logic**: `GameLogicService` compares metrics to targets and awards
  score increments for consistent cadence and stability.
- **Exports**: summaries can be exported via `GithubExportService` for review
  and auditing.

## Core invariants

- Metrics outputs are bounded, deterministic, and test-backed.
- Any change to metric math requires unit test updates and documentation updates.
- CI enforces formatting, analysis, tests, and security checks on every PR.
