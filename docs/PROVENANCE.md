# Provenance and unresolved questions (2026-11-17)

The following files were directly inspected via the connected GitHub repository:

| Source file | Git blob SHA |
| --- | --- |
| `PrepPipeline/utilities/blasst/blasst.m` | `3a00a1a02bbacbc0b8310241d51174e81d51f223` |
| `PrepPipeline/utilities/blasst/blasst_internal.m` | `a3527c0317f28054ae75f21de23fd78b000f2f98` |
| `PrepPipeline/utilities/blasst/blasst_test.m` | `daf2d90814cc04f1fb3f42a1fed00da976142047` |
| `PrepPipeline/utilities/blasst/pop_blasst.m` | `f350c8c762cfaa020089039861ea99dffa09b29d` |
| `PrepPipeline/utilities/blasstLineNoise.m` | `5eda0fefe6b545968b34387620bc3c28878234fd` |

The corresponding source-tree link was at commit `0914132081ea7d534ee19f96973791fd81825755`: `https://github.com/VisLab/EEG-Clean-Tools/tree/0914132081ea7d534ee19f96973791fd81825755/PrepPipeline/utilities/blasst`.

The authors' independent original repository `VisLab/blasst` also exists; its public `blasstOriginal.m` is at revision `bc0785c635c0baa68efafa9ca5cdf7ca23965b12`. Kay Robbins said in emails dated March 1, 2023 that the `Original` suffixed files were Ken Ball's implementation and the later files were her unfinished usability-oriented revisions.

## Two source-level discrepancies that matter

1. The PREP wrapper contains `blasst(..., 'MaximumIterations', maxIterations, ...)`, but `blasst.m` switches only on `'MaxIterations'`. Therefore, the lower-level default 50 iterations may have applied despite the experimental script requesting 10. The test should print an actual count of accepted passes; stopping before 10 makes the discrepancy practically moot for that dataset.
2. `blasst.m` contains `if ~exist('scaleBases','var'), scale = 2^(log2(samplingRate)+2); end`. Since `scaleBases` is not otherwise defined in the inspected function, a caller-supplied `Scale` is overwritten. At 250 Hz this default is 1000 samples = 4 s; at 500 Hz it is 2000 samples = 4 s, exactly the paper's requested value. At other requested scales this bug changes the algorithm.

The local manuscript script `p0342_compareLineNoiseRemoval_20260809_mm(1).m` and the uploaded `lineNoiseRemovalPaper-main.zip/Simulation.m` request `lineNoiseIn.maximumIterations = 10`, `lineNoiseIn.scale = 4*Fs` and call `blasstLineNoise`. These are requests at the wrapper level; they do not establish the implementation's effective lower-level settings. A locally patched `blasst.m` or `blasstLineNoise.m` could behave differently.

## Correspondence distilled

- 2023-03-01, Kay: the PREP implementation was a later, incompletely debugged attempt; the original source and PREP should not be assumed equivalent.
- 2023-03-02, Yasuhisa: comparing versions at different scales (0.5 s vs 4 s) was confounded; smaller scales could remove more line power at the cost of target-signal attenuation.
- 2024-01-11, Kay: PREP version was not fully implemented/debugged; long data need independent sections plus stitching.
- 2026-11-16, Kenneth Ball: endorses creating an EEGLAB standalone plugin and offers help.
- 2026-11-16, Kay: states a plugin is fine; recommends roughly five-minute segments for practical computation but cautions about implementation quality.
- 2026-11-16, Makoto: proposes reusing the published-study implementation rather than creating a novel algorithm, respecting Kay's concerns.

## Validation received on November 17, 2026

The Windows 11 report documents six executed MATLAB tests. It confirms a synthetic 4-second-scale parity result against the pinned public PREP core (relative L2 error `5.28061548092e-16`), confirms the incorrect `Scale` override in the public code, and confirms that `MaximumIterations` is ignored by the public lower-level function. Neither R2022b nor a historical paper source was exercised. This means *public code parity* is established for one deterministic input, but *paper source parity* is not.

The manuscript analysis script explicitly adds `BLASST_PREPpipeline` and its `blasst` subdirectory to the MATLAB path. Its `lineNoiseIn` requests `scale=4*Fs` and `maximumIterations=10`, but the script does not establish which implementations of `blasstLineNoise` and `blasst` were resolved at runtime. No original historical source-file copy or complete runtime path log was provided in the current attachments. A separate source audit documents what is and is not inferable; see `SOURCE_AUDIT_20261117.md`.

## Remaining blockers

- Which exact historical PREP source files produced the final Cortex figures? Git clone revision of the local `BLASST_PREPpipeline` folder, if any, plus local modifications and actual runtime path precedence.
- Does `test_blasst_legacy_parity.m` pass on the pinned public version and on the paper's historical source with identical input data?
- Does changing maxIterations from 10 to 50 change any result? Record per-channel accepted passes.
- Does finite segmentation alter the waveform or create discontinuities? Comparison must include time-domain ground truth, not only PSD.
- EEGLAB history, GUI, and menu callback behavior were tested successfully with R2024b/EEGLAB 2024.0; on-disk `.set` save-and-reload and R2022b behavior still require verification.

MATLAB and EEGLAB were run by ChatGPT Work on the user's Windows 11 computer for the documented tests. The Chat environment itself did not execute MATLAB. Refer to VALIDATION_REPORT_20261117.md for the exact outcomes and their limits.


## v0.3.0-dev dual implementation staging

All v0.2.0-dev `+blasstcore/*.m` files are preserved byte-for-byte.
The optimized implementation is imported from the separate validated
`+blasstoptACH` package. A new `+blasstdispatch` package switches channel
processing without modifying the underlying legacy mathematical functions.
The GUI label intentionally says PREP-derived adapted port and does **not**
claim the original authors' public functions were imported verbatim.
