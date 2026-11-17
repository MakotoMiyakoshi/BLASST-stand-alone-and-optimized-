# Historical BLASST source audit (2026-11-17)

## Verified against the supplied local scripts

- In `p0342_compareLineNoiseRemoval_20260809_mm(1).m`, lines 160-172 add `BLASST_PREPpipeline` and its `blasst` subfolder to the MATLAB path, construct `lineNoiseIn` with `Fs=EEG.srate`, `lineFrequencies=60`, `fScanBandWidth=2`, `maximumIterations=10`, and `scale=4*EEG.srate`, then call `blasstLineNoise(EEG,lineNoiseIn)`.
- The archive `lineNoiseRemovalPaper-main.zip` contains `Simulation.m` and `ICcoef.mat`, but does **not** contain the `BLASST_PREPpipeline` implementation. In `Simulation.m` (lines 165-168), the same iteration and scale request appears before `blasstLineNoise` is called.
- The explicit `addpath(...,'-begin')` statements mean path precedence is significant. Neither source contains the output of MATLAB `which -all` at the historical run.

## Verified from the public code, not the historical study source

Public PREP repo `VisLab/EEG-Clean-Tools`, pinned commit `0914132081ea7d534ee19f96973791fd81825755`, contains a `blasstLineNoise.m` wrapper and lower-level `blasst.m` with these parameter issues:

1. Wrapper calls `blasst(...,'MaximumIterations',maxIterations,...)`; lower-level option parser recognizes `MaxIterations`, **not** `MaximumIterations`. The lower-level maximum therefore stays at its default 50 on this public revision.
2. Lower-level `blasst.m` checks `exist('scaleBases','var')` instead of whether `scale` exists, and assigns `scale=4*samplingRate`. A user-supplied `Scale` is effectively ignored. The manuscript's **intended** 4-s scale coincides with this forced default.

ChatGPT Work experimentally verified both public-code discrepancies and synthetic parity with the new plugin's whole-record, 4-s case (relative L2 error about `5.28e-16`). That does **not** determine whether the historical study source was patched or whether its results are identical.

## What remains unknowable from the presently supplied material

The exact contents, checksums, modification timestamps and runtime resolution of the historical `BLASST_PREPpipeline/blasstLineNoise.m` and `BLASST_PREPpipeline/blasst/blasst.m`, `blasst_internal.m`, `blasst_test.m` are not available. It is not yet demonstrated that the effective maximum in the study was 10 or 50, or that all channels stopped in fewer than 10 passes. No reanalysis or change to the published scientific results is justified by these sources alone.

## Next Windows-only action, after the historical folder is located

1. Preserve a read-only copy of the original historical BLASST source or record SHA-256 checksums before testing.
2. Start a fresh MATLAB session and record `which -all blasstLineNoise`, `which -all blasst`, `which -all blasst_internal`, `which -all blasst_test`, `path`, `version`, and file checksums. **Do not** alter the manuscript project or any p-numbered output directory.
3. Run the optional `test_blasst_historical_wrapper_parity(historicalFolder)` on synthetic data. It temporarily adjusts the MATLAB path and restores it. Record all numerical differences for candidate maximums 10 and 50; this is a diagnostic rather than proof of paper parity.
4. On a deidentified, permission-cleared reference dataset with frozen preprocessing, if available, compare exact original denoised waveform outputs with the new plugin, logging per-channel accepted passes and waveform/PSD changes. Do not infer comparability from PSD flattening alone.

**Stop condition:** Historical source absent or ambiguous => paper-source parity remains UNVERIFIED. The plugin remains a development candidate. No publication or modification of existing research-output files.
