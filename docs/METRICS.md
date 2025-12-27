# Metrics Constitution

This document defines the **production contract** for motion metrics. All
metrics are deterministic, bounded, and mathematically stable under the same
input samples.

## Inputs

- `MotionSample.t`: seconds since start.
- `MotionSample.position`: 2D normalized coordinates (0..1 in UI space).
- `expectedAmplitude`: normalization reference (typically 0.5 for screen space).

Derived values:

```
dt = t(i) - t(i-1)
sampleRateHz = 1 / mean(dt)
Δp(i) = p(i) - p(i-1)
```

## Metrics

### Consistency Score (0..100)

**Purpose:** How stable the speed is across time.

```
speed(i) = |Δp(i)| / dt
meanSpeed = mean(speed)
stdSpeed = std(speed)
cv = stdSpeed / (meanSpeed + eps)

jerk(i) = speed(i) - speed(i-1)
jerkStdNormalized = std(jerk) / (meanSpeed + eps)

consistency = clamp(100 - (cv * 100) - (jerkStdNormalized * 20), 0..100)
```

**Invariants:**
- Constant velocity ⇒ consistency ≥ 95.
- Random jitter ⇒ consistency < 60.

### Frequency (Hz) + Confidence (0..1)

**Purpose:** Detect rhythmic motion without frequency doubling.

1. Principal axis (PCA) over mean-centered positions:

```
meanP = mean(p)
Cov = cov(p - meanP)
principalAxis = eigenvector(maxEigenvalue(Cov))
```

2. Project positions to signed scalar signal:

```
s(t) = dot(p(t) - meanP, principalAxis)
```

3. Autocorrelation on mean-centered `s(t)`:

```
r(k) = Σ s0(t) * s0(t+k),  s0 = s - mean(s)
```

4. Search in `[minLag, maxLag]` where:

```
minLag = floor(sampleRateHz / 10)
maxLag = ceil(sampleRateHz / 0.5)
```

5. Select the first significant local maximum; otherwise use the global max.
   Refine the lag via parabolic interpolation and return:

```
frequencyHz = sampleRateHz / refinedLag
confidence = clamp(rPeak, 0..1)
```

**Invariants:**
- Sine 2Hz ⇒ frequency ≈ 2Hz (±0.3), confidence > 0.5.
- Mixed tones ⇒ confidence < 0.7.
- Noise ⇒ confidence < 0.3.

### Direction Vector

**Purpose:** Net movement direction (signed, non-mean-centered).

```
v = Σ Δp(i)
if |v| < eps → direction = (0,0)
else direction = v / |v|
```

**Invariants:**
- Leftward motion ⇒ direction.x < 0.
- Circular motion ⇒ direction ≈ (0,0).

### Direction Stability (0..100)

**Purpose:** Smoothness of motion regardless of absolute direction.

```
directionStability = clamp(100 - (cv * 50) - (jerkStdNormalized * 20), 0..100)
```

If `direction == (0,0)`, stability is `0`.

**Invariants:**
- Smooth sinusoid ⇒ directionStability > 70.
- Random jitter ⇒ directionStability < 40.

### Intensity (0..100)

**Purpose:** Energy per unit spatial scale.

```
spatialScale = sqrt(var(x) + var(y))
intensity = clamp(100 * meanSpeed / (spatialScale * sampleRateHz * scale + eps), 0..100)
```

`scale` is tuned for test baselines: fast > 60, slow < 40.

### Pattern Match (0..100)

**Purpose:** Similarity to a reference trajectory using normalized MSE.

```
mse = mean((observed(t) - target(t))^2) / expectedAmplitude^2
score = 100 / (1 + mse / tolerance^2)
```

## Failure Modes & Test Coverage

| Failure mode | Guardrail / Test |
| --- | --- |
| Frequency doubling from |v| | `frequency is not doubled by abs projection` |
| Drift in frequency | `frequency detects dominant sine component` |
| Noise inflates confidence | `frequency confidence drops on noise` |
| Direction sign flipped | `direction respects net motion sign` |
| Random walk appears stable | `random walk yields low consistency` |

## Ranges & Clamping

All scores are clamped to `[0, 100]`. Any non-finite values are treated as
invalid and coerced to `0` by construction.
