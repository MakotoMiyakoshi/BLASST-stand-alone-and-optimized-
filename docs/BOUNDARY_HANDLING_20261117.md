# Boundary-aware BLASST handling - 2026-11-17

## User decision

Policy A: process each sufficiently long continuous interval independently; leave every shorter interval exactly unchanged. Do not stop merely because EEGLAB records a boundary. Do not concatenate across discontinuities, interpolate, drop samples, alter the Gabor scale to force processing, or fit across boundary positions.

## Implementation

- `pop_blasst_standalone` calls `blasstcore.boundaryCuts(EEG.event,N)` on one-trial continuous datasets. An EEGLAB boundary at latency `K+0.5` yields cut `K` (last sample in the preceding interval). Boundary markers at `0.5` and `N+0.5` yield no interior cut; duplicates are deduplicated. Non-boundary event types are ignored (without changing them). Invalid numeric boundary latencies raise `BLASST:Boundary`.
- The parser in `blasst_standalone` accepts internal `BoundaryCuts` and `BoundaryEventCount`. All existing analysis parameters retain their defaults and validation. The data array is segmented into `start:end` slices; each eligible slice is passed independently to the *same* preexisting `denoiseRecord` or optional `denoiseSegmented` function, with no overlap across true boundaries.
- Eligible slices have at least `max(8*round(ScaleSeconds*Fs)+1,round(10*Fs))` samples. This is a conservative current-code guard. Ineligible slices remain exactly their input data, and their removed signal remains exactly zero. When every slice is skipped and at least one boundary event exists, return an unchanged dataset, a warning and a report.
- One `BLASST:ShortSegments` warning per processed dataset counts skipped slices and percentage of original time samples. `skippedSampleFraction` is a fraction between zero and one. A sample is counted only once even if a boundary event is duplicated.
- `report.acceptedIterations` is the maximum over independent intervals (as in the existing finite-segmentation convention). Exact per-interval counts are `acceptedIterationsByContinuousSegment`, indexed by channel, target frequency, interval, and trial. `continuousSegmentRanges`, `skippedSegmentRanges` and `processedSegmentRanges` use inclusive one-based sample indices.
- The source EEGLAB `EEG.event`, `EEG.pnts`, `EEG.trials`, `EEG.srate` and channel dimensions are not explicitly modified. The original `eeg_checkset` call remains for EEGLAB consistency checking.
- Epoched trials still have no `BoundaryCuts` and are processed as separate trials as previously; an epoched recording shorter than the plugin minimum remains an error rather than being silently filtered.

## Distinct from finite segmentation

Boundary-separated processing is required to respect known signal discontinuities. `SegmentSeconds` finite still indicates an **optional, experimental** context-overlap approximation *inside* a continuous interval. Neither should be represented as equivalent to fitting the entire concatenated record in one pass.

## Validation state

Previously: six MATLAB tests, one public PREP synthetic parity test, prior GUI entry and Cancel passed on Windows 11 / MATLAB R2024b / EEGLAB 2024.0 (see prior frozen `VALIDATION_REPORT_20261117.md`).

This revision: two **new, not-yet-run MATLAB tests** were authored:

1. `test_blasst_boundary`: repeated/edge events; skipped span unchanged; exact equivalence to independently processing eligible subrecords; same result without cuts; all-short no-op with explicit warning and report; invalid cuts.
2. `test_blasst_boundary_eeglab`: actual EEGLAB event metadata and latency preservation, channel passthrough, skip count, and generated command replay.

Neither these new tests nor the revised static-reference GUI have yet been executed in MATLAB after this change. Do not declare this revision production-validated or publication-ready until this has been done. The historical Cortex manuscript source implementation also remains unidentified.
