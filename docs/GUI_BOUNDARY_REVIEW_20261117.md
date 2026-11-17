**Historical note:** This design memo describes the state of the previous *GUIrefs* ZIP. Boundary behavior proposed here has now been implemented under policy A in `BOUNDARY_HANDLING_20261117.md`. Its earlier statements that boundary handling was unimplemented are no longer applicable to this distribution.

# BLASST GUI revision and boundary design review — 2026-11-17

## Implemented (GUI only)

- Replaced MATLAB `inputdlg` (which necessarily renders each citation as an editable text box) with a modal dialog using seven editable controls and three static text controls for the `Reference` heading and two citations.
- Preserved labels, defaults, parameter parsing, Cancel semantics, command-history generation, and existing `pop_blasst_standalone` API.
- Algorithm and boundary-rejection code remain byte-for-byte equivalent to the preceding reviewed release, aside from the GUI block.
- Modified `pop_blasst_standalone.m`, added `+blasstcore/settingsDialog.m` and `+blasstcore/finishSettingsDialog.m`, and updated README.
- Tests previously passed for the reviewed candidate in MATLAB R2024b / EEGLAB 2024.0. **The revised GUI has not been executed in MATLAB here.**

## Boundary design proposed for discussion, not implemented

1. Read `EEG.event` boundaries and derive sample-exact contiguous stretches. Ordinary boundaries at `N+0.5` split after sample N; a boundary at 0.5 or `EEG.pnts+0.5` is edge-only. Preserve all samples and events without any edits.
2. Call whole-stretch BLASST independently on each sufficiently long stretch, using identical settings and no overlap across a discontinuity. This is a principled definition but yields **different per-stretch stopping decisions** from filtering the concatenated signal.
3. A short stretch below the current plugin's minimum required duration (max(8 * Gabor scale, 10 seconds), in samples) cannot be fed to `blasst_standalone` unchanged. Two alternatives are: (a) leave it untouched and report its exact coverage and why (recommended for maximum usability with explicit warnings); (b) stop and ask for different Gabor scale or preprocessing (strict mode). Automatically shrinking Gabor scale is **not** recommended as it changes the effective method in a data-dependent way.
4. Boundary-aware behavior needs a documented chosen default, explicit `report` entries per stretch, tests for boundaries at N+0.5, at the start/end, repeated boundaries, arbitrary `EEG.event.type`, short spans, channel selection, history-replay fidelity, and unchanged event timing.

## Scope

This is not a research-ready or published release. The historical 2026 Cortex source remains unidentified; this revision is solely GUI appearance.
