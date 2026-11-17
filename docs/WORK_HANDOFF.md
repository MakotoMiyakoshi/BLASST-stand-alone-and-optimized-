**Boundary-aware update (2026-11-17):** Before continuing historical parity checks, run `test_blasst_boundary` and `test_blasst_boundary_eeglab` against this exact candidate in MATLAB R2024b / EEGLAB 2024.0; rerun the original tests for regression; manually test the updated static-reference GUI on a dataset containing boundary events. The implementation now uses approved policy A (short continuous intervals unchanged, warning and report). The prior `VALIDATION_REPORT` pertains to the preceding build. Report newly verified outcomes separately; do not modify research pipeline output directories.

# BLASST Work handoff - remaining Windows 11 provenance tasks

The initial Win 11 validation is complete. See `VALIDATION_REPORT_20261117.md` before rerunning anything. MATLAB R2024b Update 3 / EEGLAB 2024.0 smoke and GUI tests, plus one public PREP parity test, have passed. Do **not** repeat them merely for reassurance or spend resources reinstalling the same code. The plugin's numerical MATLAB core has not been changed since those tests; this package contains documentation updates and an optional additional diagnostic test.

## Narrow remaining goal

Locate the *actual* `BLASST_PREPpipeline` source used to run the Cortex manuscript's `p0342_compareLineNoiseRemoval_20260809_mm(1).m`, **without** modifying existing projects or output directories. Its referenced parent project is a historical Linux path, not an established Windows path. Do not guess its present location.

If the source exists, preserve its content or SHA-256 hashes; record `which -all` results (all four functions), version and path precedence. Only after resolving a unique source, run the new `test_blasst_historical_wrapper_parity(historicalFolder)` using synthetic data. That function is unexecuted and may need small Windows compatibility fixes. Do not silently edit the algorithm; report failures and numerical differences for MaxIterations=10 and 50. If the historical source is unavailable, report that plainly and stop.

Do not publish, push, edit project scripts, overwrite `.set` files, modify permanent MATLAB settings, or write into an immutable p-numbered output directory. No interactive changes to the user's analysis. Ask before any exceptional file organization.

## Report

Provide: exact resolved historical source paths, checksums, availability, pass/fail for the optional diagnostic, differences against the new candidate, and any scientific provenance uncertainties. GUI citations have already been added and confirmed; do not revisit them.
