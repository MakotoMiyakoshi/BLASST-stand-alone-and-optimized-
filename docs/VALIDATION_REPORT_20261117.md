# BLASST Standalone Windows 11 validation — 2026-11-17

## Environment and candidate

- Tested MATLAB 24.2.0.2806996 (R2024b Update 3), `C:\Program Files\MATLAB\R2024b`. R2022b is also installed at `C:\Program Files\MATLAB\R2022b` but was not tested.
- EEGLAB 2024.0: `C:\GYREE\eeglab2024.0`. Only temporary MATLAB session paths were changed.
- Candidate: supplied `BLASST_Standalone_EEGLAB_v0.1.0-dev.zip`, extracted into `candidate/BLASST_Standalone_0.1.0-dev`. Its MATLAB code matched the workbench copy before the citation-only GUI change.
- Public PREP reference pinned to commit `0914132081ea7d534ee19f96973791fd81825755`; blob IDs: `blasst.m` `3a00a1a02bbacbc0b8310241d51174e81d51f223`, `blasst_internal.m` `a3527c0317f28054ae75f21de23fd78b000f2f98`, `blasst_test.m` `daf2d90814cc04f1fb3f42a1fed00da976142047`. The local copies match those Git blob hashes.

## Results

| Test | Result | Elapsed |
| --- | --- | ---: |
| `test_blasst_smoke` | PASS | 0.624 s |
| `test_blasst_validation` | PASS | 0.057 s |
| `test_blasst_segments` | PASS, bookkeeping only | 0.116 s |
| `test_blasst_quality_metrics` | PASS, no waveform acceptance threshold | 0.091 s |
| `test_blasst_eeglab` | PASS | 0.370 s |
| `test_blasst_legacy_parity` | PASS, relative L2 error `5.28061548092e-16` | 0.665 s |

Ground-truth RMSE before/after, respectively: burst `0.818650/0.472376`, peri-burst `0.802153/0.022737`, no-signal `0.715416/0.007763`. This diagnostic does not establish an acceptable signal-preservation threshold.

Synthetic adapter checks: excluded channel unchanged, `single` class and dimensions retained, generated command history replayed with maximum absolute data difference `0`, and boundary events rejected with `BLASST:Boundary`. The actual EEGLAB window accepted a BLASST entry under Tools when registered in memory; no permanent plugin installation was made. GUI defaults executed successfully (4 s scale = 1000 samples, maximum 50, two accepted iterations). Cancel left the dataset, command string, and report unchanged. Both citations appeared in the GUI dialog.

## Parameter provenance and blockers

- Candidate with requested 4 s / maximum 10 used 1000 samples / maximum 10; one iteration was accepted on the diagnostic signal. Requested 0.5 s used 125 samples.
- Pinned PREP code overwrites a caller's `Scale`: requested 0.5 s and 4 s gave identical outputs (maximum absolute difference `0`). Its `MaximumIterations` argument is ignored; only `MaxIterations` is recognized. On this synthetic input, requested maximum 10 and 50 also gave identical outputs because stopping occurred early. Candidate 0.5 s versus legacy's purported 0.5 s differed by maximum absolute `0.135769311297`.
- **Blocker:** The exact historical source and runtime path used for the Cortex figures remain unidentified. Public-source parity cannot establish study-source parity. Finite segmentation and waveform preservation also lack an acceptance criterion. Do not claim research readiness on these results.

## Minimal corrections proposed

1. Establish the historical source revision and its effective MATLAB path; record actual per-channel accepted iterations on the study data. If the historical wrapper intended 10 iterations, change its argument name from `MaximumIterations` to `MaxIterations` only after the resulting numerical change is reviewed.
2. Document that the pinned PREP implementation forces a 4 s scale; retain the candidate's explicit scale handling and compare any non-4 s run against a properly corrected reference.
3. Define a waveform-preservation criterion and test segmentation against whole-record processing before using segmented mode for research.

Changed files are confined to this workspace: one candidate GUI file (`pop_blasst_standalone.m`), isolated test scripts/logs, pinned reference copies, this report, and a separately packaged citation-updated ZIP. The supplied ZIPs and research outputs were not modified; no permanent MATLAB path setting, publication, or GitHub push was made.
