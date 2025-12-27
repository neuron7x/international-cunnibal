# Motion Metrics Contracts

This document defines the formal contracts and invariants for `MotionMetrics`.

## Definitions

All metrics must be deterministic, bounded, and free of NaN/Infinity.

### Direction

* `Direction.axis`: unit vector representing the dominant motion axis; `(0,0)` when undefined.
* `Direction.stability ∈ [0, 100]`: axis-consistency score.

Axis computation:

1. Perform PCA on displacement vectors to estimate the dominant axis.
2. If PCA degenerates (trace ≈ 0), fall back to the normalized net displacement.
3. Orient the axis so it aligns with the net displacement sign.

Stability:

For each displacement `d_i`, compute `u_i = normalize(d_i)` and
`cos_i = abs(dot(u_i, axis))`. Then:

```
stability = clamp(100 * mean(cos_i), 0..100)
```

### Consistency

* `Consistency ∈ [0, 100]`: variability of motion speed along the axis.
* Uses the absolute projected speed.

```
speed_i = abs(dot(displacement_i, axis) / dt)
consistency = clamp(100 * (1 - std(speed) / (mean(speed) + eps)), 0..100)
```

### Intensity

* `Intensity ∈ [0, 100]`: normalized speed magnitude.
* Uses expected amplitude for normalization.

```
s_i = abs(dot(displacement_i, axis) / dt) / expectedAmplitude
intensity = clamp(100 * mean(s_i), 0..100)
```

### Frequency

* `Frequency.hz ≥ 0`, `confidence ∈ [0, 1]`.
* Computed from the projection of positions onto the axis.

Signal:

```
p_i = dot(position_i, axis)
```

Autocorrelation is computed on the mean-centered, Hann-windowed signal. The
dominant lag yields:

```
hz = sampleRate / lag
confidence = clamp(bestR / r0, 0..1)
```

Low-confidence or out-of-range results return `hz = 0`.

## Invariants

* No NaN/Infinity values.
* Stationary input ⇒ `frequency=0`, `intensity=0`, `consistency=100`.
* Linear constant motion ⇒ `direction.stability ≥ 80` and correct sign.
* Sine motion at `2Hz` ⇒ `frequency ≈ 2Hz` (±0.3).
* Frequency is derived from axis-projected positions (not `|v|` magnitudes).
