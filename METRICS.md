# Motion Metrics Constitution

This document defines the formal contracts and invariants for `MotionMetrics`.

## Inputs

`MotionMetrics.compute` consumes a list of `MotionSample` values with time `t` in
seconds and 2D positions in normalized screen space.

## Outputs

All outputs are deterministic, clamped, and finite:

- `consistency ∈ [0, 100]`
- `frequency.hertz ≥ 0`
- `frequency.confidence ∈ [0, 1]`
- `direction.direction` is a unit vector (or `(0,0)` when undefined)
- `direction.stability ∈ [0, 100]`
- `intensity ∈ [0, 100]`
- `patternMatch.score ∈ [0, 100]`

## Direction

Direction is based on *net displacement* (not mean-centered):

```text
Δp(t) = p(t) - p(t-1)
v = Σ Δp(t)
if |v| < eps → direction = (0,0)
else direction = v / |v|
```

## Speed Statistics

Speeds are computed from displacement magnitudes:

```text
speed(t) = |Δp(t)| / dt
meanSpeed = mean(speed)
stdSpeed = std(speed)
cv = stdSpeed / (meanSpeed + eps)

jerk(t) = speed(t) - speed(t-1)
jerkStd = std(jerk)
jerkStdNormalized = jerkStd / (meanSpeed + eps)
```

## Consistency

```text
consistency = clamp(100 - (cv * 100) - (jerkStdNormalized * 20), 0..100)
```

## Direction Stability

Direction stability reflects smoothness (low speed variability and jerk):

```text
directionStability = clamp(100 - (cv * 50) - (jerkStdNormalized * 20), 0..100)
```

If `direction == (0,0)`, stability is `0`.

## Frequency

Frequency is computed from a signed projection on the principal axis derived
from PCA over **mean-centered positions** (to avoid frequency doubling):

1. Compute principal axis `u` from covariance of positions.
2. Project positions: `s(t) = dot(p(t) - mean(p), u)`.
3. Autocorrelation on centered signal:

```text
r(k) = Σ s0(t) * s0(t+k),   s0 = s - mean(s)
```

4. Search for a peak within the lag window:

```text
minLag = floor(sampleRate / maxHz)
maxLag = ceil(sampleRate / minHz)
```

5. Choose the first significant local maximum (or global max fallback), then
   refine with parabolic interpolation.

```text
frequencyHz = sampleRate / refinedLag
confidence = clamp(rPeak, 0..1)
```

If the signal variance is near zero, frequency and confidence return `0`.

## Intensity

Intensity captures movement energy relative to spatial scale:

```text
spatialScale = sqrt(var(x) + var(y))
intensity = clamp(100 * meanSpeed / (spatialScale * sampleRate * scale + eps), 0..100)
```

`scale` is tuned so that fast trajectories exceed `60` and slow trajectories are
below `40` in tests.

## Pattern Match

Pattern match uses normalized MSE against a target trajectory (interpolated to
match timestamps):

```text
mse = mean((observed(t) - target(t))^2) / expectedAmplitude^2
score = 100 / (1 + mse / tolerance^2)
```

## Invariants

- No NaN/Infinity values.
- Stationary input ⇒ `frequency=0`, `intensity=0`, `direction=(0,0)`.
- Constant-velocity input ⇒ `consistency ≥ 95`, `directionStability ≥ 80`.
- Sine at 2Hz ⇒ `frequency ≈ 2Hz (±0.3)`, `confidence > 0.5`.
- Random jitter ⇒ low consistency, low direction stability, low confidence.
