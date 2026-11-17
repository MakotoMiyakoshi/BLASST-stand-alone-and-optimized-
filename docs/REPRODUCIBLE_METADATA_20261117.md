# BLASST v0.3.2-dev — Reproducible processing metadata

The `pop_blasst_standalone` EEGLAB entry point stores a structured record in
`EEG.etc.BLASST` each time a successful processing operation finishes.
The previous `EEG.etc.blasst_standalone` performance report is retained for
backward compatibility. Neither legacy nor optimized numerical kernels were
modified in this update.

## Version names

- `EEG.etc.BLASST.version = 'Optimized'`: the separate `+blasstoptACH`
  accelerated implementation, which remains the default.
- `EEG.etc.BLASST.version = 'Original'`: the unchanged `+blasstcore`
  **PREP-derived adapted port**, *not* a byte-exact copy of Kenneth Ball's
  `blasstOriginal*.m` repository. The exact provenance is separately recorded
  in `implementationSource`.
- `pluginVersion = '1.0.0'` is the installed plugin release identifier.
  The `version` field above identifies the **selected algorithm variant**,
  not the plugin release number.

## Parameter fields

The most frequently used effective inputs are stored directly as
`lineFrequencies`, `halfBandwidths`, `scaleSeconds`, `scaleSamples`,
`resolution`, `maxIterations`, `channels`, `segmentSeconds`,
`segmentSamples`, `executionMode`, `parallelWorkerCount`, `showProgress`,
`samplingRate`, `boundaryCuts`, and `boundaryEventCount`.

`inputParameters` stores *every* parsed option from the core's `inputParser`
(including parameters left at their default and boundary cuts calculated
from EEGLAB events). `defaultedParameters` lists options which took their
core defaults. `effectiveParameters` records normalized widths, rounded
Gabor scale in samples, actual segment length, and the selected method.
There are also `continuousSegmentRanges`, `processedSegmentRanges`,
`skippedSegmentRanges`, `minimumSamplesRequired`, and accepted-iteration
counts for interpreting boundary handling.

`inputDataset` records the dimensions, data class, sampling rate, and
available identifying metadata of the **unprocessed input**. No duplicate
raw EEG samples are stored in `EEG.etc`.

## Reproduction

On the **original unprocessed input dataset** (`originalEEG`), re-run the
numeric core with the exact recorded parameters, including the original
boundary cut positions:

```matlab
m = processedEEG.etc.BLASST;
[clean, removed, rep] = blasst_standalone( ...
    originalEEG.data, originalEEG.srate, m.coreReplayArguments{:});
```

For EEGLAB history, `replayCommand` stores the complete command that the
plugin returned to EEGLAB, including the implementation selector. `eegh()`
can still show the chronological commands recorded by the EEGLAB GUI.
The wrapper's replay command derives `boundaryCuts` from the **current**
`EEG.event`, whereas the core replay arguments preserve the **actual** cuts
used. Both need the original input EEG; running either on the already
cleaned EEG would apply BLASST again, not reverse an earlier operation.

The metadata alone cannot recreate missing original data, an unavailable
pinned implementation, or a different MATLAB execution environment.
For strict bitwise reproduction, retain the original input data and the
same source version, MATLAB version and numerical environment.

## Console/progress

The implementation is always announced in the MATLAB console, even if
`ShowProgress=false`. In the EEGLAB GUI (`ShowProgress=true` by default),
Legacy and Optimized share the same interval-aware progress popup and
estimated remaining time. The unnecessary full-record slow warning remains
removed. Warnings about *actual unprocessed short boundary intervals*
remain active because these change the filtering coverage.

## Test

Run `tests/test_blasst_etc_metadata.m` in MATLAB to validate these fields,
serial replay, the Optimized default and both implementations. Regression
of GUI rendering and parallel callbacks also requires a local MATLAB/EEGLAB
session.
