# BLASST Standalone v1.0.0 — EEGLAB plugin

BLASST (Band-Limited Atomic Sampling with Spectral Tuning) line-noise
removal for EEGLAB. The plugin provides **two explicitly selectable**
implementations, common boundary-aware channel handling, reproducible
processing metadata, and optional channel-parallel execution.

## Installation

Unzip this distribution and place its single `BLASST_Standalone_1.0.0`
folder under the EEGLAB `plugins` directory. Remove older BLASST
Standalone copies from the active EEGLAB plugin path before restarting
EEGLAB. In EEGLAB, choose **Tools > BLASST**.

## Defaults

- **Implementation:** Optimized (7-smooth FFT, selected Gabor atoms,
  exact filter-FFT caching, histogram counting).
- **Execution mode:** Serial. Parallel is an optional explicit selection
  requiring the Parallel Computing Toolbox.
- **Progress:** Interactive progress popup and estimated remaining time.
- **Core segment length:** `Inf` (whole continuous interval; real EEGLAB
  boundary events split independent intervals). Short intervals that
  cannot support the selected scale are left unchanged and reported.
- **Display:** traditional EEGLAB colors (background `[0.66 0.76 1]`,
  label text `[0 0 0.4]`, user-edit text `[0 0 0]`, button background
  `[0.93 0.96 1]`).

## API and reproducibility

```matlab
[EEG, command, report] = pop_blasst_standalone(EEG, ...
    'Implementation','optimized', ...
    'LineFrequencies',50, ...
    'HalfBandwidths',2, ...
    'ScaleSeconds',4, ...
    'Resolution',2, ...
    'MaxIterations',50, ...
    'ExecutionMode','serial');
```

Set `'Implementation','legacy'` to select the PREP-derived adapted
implementation. `EEG.etc.BLASST.version` records `Optimized` or
`Original` (the implementation label), while
`EEG.etc.BLASST.pluginVersion` records `1.0.0` (the release version).
All parsed and effective inputs, boundary cuts, and core replay arguments
are recorded in `EEG.etc.BLASST`. EEGLAB command history (`eegh`) is
supported. Replaying requires the *original, unprocessed* EEG.

## Source attribution and testing scope

The Legacy core in `+blasstcore` is a PREP-derived **adapted port**, not a
byte-exact copy of Kenneth Ball's separate `blasstOriginal*.m` source.
The Optimized core is in `+blasstoptACH`. Original copyright and
Apache-2.0 attribution are retained. See `docs/PROVENANCE.md`.

Serial performance and close numerical agreement between the two cores
were benchmarked in MATLAB R2024b Update 3 / EEGLAB 2024.0, with
30-minute × 33-channel performance results reported in the technical
optimization report. The user additionally confirmed identical `single`
EEGLAB output for a one-channel, boundary-rich ~63-minute dataset, with
11.9 s optimized versus 42.0 s legacy processing time.
These comparisons do not establish mathematical identity for all inputs
or fully validate every MATLAB release. Installation and GUI tests should
be run in the user's own MATLAB environment.

MATLAB regression tests are included in `tests/` (especially
`test_blasst_implementation_switch`, `test_blasst_etc_metadata`,
`test_blasst_gui_presentation`, and `test_blasst_boundary_eeglab`).
Historical development notes and their original validation limitations
are preserved under `docs/DEVELOPMENT_HISTORY_20261117.md`.

## References

- Ball KR, Hairston WD, Franaszczuk PJ, Robbins KA. *IEEE Transactions
  on Biomedical Engineering*. 2017;64(9):2276–2287.
  DOI: 10.1109/TBME.2016.2632119.
- Maruyama Y et al. *Comparing line-noise removal algorithms for EEG
  data processing*. *Cortex*. Online 7 November 2026.
  DOI: 10.1016/j.cortex.2026.11.005.
