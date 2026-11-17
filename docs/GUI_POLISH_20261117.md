# BLASST v0.3.3-dev — EEGLAB GUI polish

## Changes from v0.3.2-dev

1. EEGLAB Tools menu label: exactly `BLASST`.
2. `pop_blasst_standalone(EEG)` GUI default `ExecutionMode='serial'` regardless of Parallel Computing Toolbox. Explicit `'ExecutionMode','parallel'` continues to work.
3. The settings dialog background is exactly `[0.66 0.76 1]`. Static labels, button labels, progress text, and the EEGLAB Tools-menu item use `[0 0 0.4]`. User-editable text and selected popup values use `[0 0 0]` on white control backgrounds. Progress window background and its static text controls also use the classic EEGLAB palette.
4. Implementation choice remains default `optimized`. `EEG.etc.BLASST.version` remains `Optimized`/`Original` according to the selected implementation, with full parameter metadata and `eegh()` replay support preserved.
5. The plugin's version and processing report version have been incremented to `0.3.3-dev`.

## MATLAB/EEGLAB verification (run on the user's workstation)

1. Keep only one active BLASST plugin folder under the EEGLAB plugins directory; restart EEGLAB. Verify Tools > **BLASST**.
2. Click it and verify the blue-background/navy-text dialog. The Execution mode popup should show **Serial** and the BLASST implementation popup should show **Optimized BLASST (default)**.
3. Explicitly switch to Parallel, then back to Serial. Verify OK and Cancel.
4. Run `tests/test_blasst_gui_presentation.m`, `tests/test_blasst_etc_metadata.m`, and existing implementation and progress regression tests.
5. Confirm `EEG.etc.BLASST.version`, history, boundary handling, progress, and numerical agreement.

This is a staging release: neither MATLAB GUI rendering nor full EEGLAB execution could be exercised in this artifact-building environment. The original/legacy numerical core and optimized core were not modified.
