# BLASST Standalone v0.3.4-dev — EEGLAB pushbutton palette fix

- OK and Cancel pushbuttons use the traditional EEGLAB button background RGB `[0.93 0.96 1]`, with navy text `[0 0 0.4]`.
- Dialog background remains `[0.66 0.76 1]`; user-input text remains black `[0 0 0]`.
- This version changes only GUI appearance and version metadata, not either numerical core.

# BLASST Standalone v0.3.3-dev — EEGLAB GUI refinements

- EEGLAB Tools menu entry shortened to exactly **BLASST**.
- Settings dialog **Execution mode** defaults to **Serial** even when Parallel Computing Toolbox is installed. Explicitly choosing Parallel is still supported.
- Settings dialog background uses classic EEGLAB RGB `[0.66 0.76 1]` and text foreground `[0 0 0.4]`. Input fields and dropdowns retain white interiors for readability; OK/Cancel button backgrounds use `[0.93 0.96 1]`. Progress-window background and text follow the same palette.
- **Optimized** remains the default implementation, with **Legacy (PREP-derived adapted port)** selectable separately.
- The numerical kernels, BLASST parameters, shared progress/ETA logic, and `EEG.etc.BLASST` metadata behavior are unchanged.
- Static source and archive checks were performed; this GUI revision still requires MATLAB/EEGLAB graphical verification on the target Windows PC.

# BLASST Standalone v0.3.2-dev — reproducible metadata

Added `EEG.etc.BLASST` (Original / Optimized variant and all input/effective parameters), console variant logging, and core replay arguments. The v0.3.1 uniform progress popup, ETA, and slow-record warning removal are retained. See `docs/REPRODUCIBLE_METADATA_20261117.md`.

# BLASST Standalone for EEGLAB - v0.3.1-dev (dual-implementation staging candidate)

## Implementation selector (v0.3.0-dev)

The GUI provides two explicitly labeled choices:

- **Optimized BLASST (default)**: separately packaged `+blasstoptACH`;
  7-smooth FFT padding, selected-atom construction, exact FFT-filter
  caching, and `histcounts`-based `hist`-compatible numerical bins.
- **Legacy BLASST (PREP-derived adapted port)**: the entire pre-existing
  `+blasstcore` implementation from v0.2.0-dev is preserved unchanged.
  This is *not* a byte-exact copy of PREP's public `blasst.m` nor Ken Ball's
  independent `blasstOriginal.m`. Do not call it unmodified original.

The API also accepts `'Implementation','optimized'` (default) or
`'Implementation','legacy'`. Both use the same top-level input checks,
boundary-aware channel routing, segmentation rules, EEGLAB integration,
and optional serial/parallel scheduling. Output reports and the replayable
`pop_blasst_standalone` command record the chosen implementation.

This artifact is a **staging candidate**, not a tested public release.
The integration has not been executed in Windows MATLAB/EEGLAB in this
environment. Confirm regression tests, boundary behavior, and GUI/history
replay before replacing an installed plugin. Separate PREP-original source
selection is a distinct provenance task and remains unresolved.

See `IMPLEMENTATION_SELECTION_20261117.md` for install and test details.


**Status (2026-11-17): The preceding candidate passed six MATLAB R2024b / EEGLAB 2024.0 tests on Windows 11, including public PREP numerical parity on one synthetic input (relative L2 error 5.28e-16). Later development added automatic boundary-aware processing, channel progress, median-based ETA, and optional channel-wise Parallel Computing Toolbox execution. These later revisions have NOT been executed in MATLAB by the authoring environment. The historical Cortex-study source is NOT identified, and segmented-mode waveform performance has NOT been validated. This remains an unreleased development candidate, not approved for research use.**

This candidate repackages the BLASST (Band Limited Atomic Sampling with Spectral Tuning) algorithm for a dedicated EEGLAB Tools menu item and scriptable `pop_blasst_standalone` call. It is not PREP and does not call `pop_prepPipeline` or `blasstLineNoise`. It uses distinct function names to avoid shadowing PREP's own `blasst.m` or `pop_blasst.m`.

## Usage

After installing the *distribution ZIP* as its own directory below the installed `eeglab/plugins` directory, restart EEGLAB and select **Tools > Remove line noise using BLASST...**. Do not install to the root of an existing research-analysis project.

From the MATLAB command line:

```matlab
[EEG, com, report] = pop_blasst_standalone(EEG, ...
    'LineFrequencies', 60, ...
    'HalfBandwidths', 2, ...
    'ScaleSeconds', 4, ...
    'Resolution', 2, ...
    'MaxIterations', 50, ...
    'Channels', 1:EEG.nbchan, ...
    'SegmentSeconds', Inf);
```

For raw matrices (channels x samples x trials):

```matlab
[clean, removed, report] = blasst_standalone(data, 250, ...
    'LineFrequencies', 60, 'HalfBandwidths', 2, 'ScaleSeconds', 4);
```

`HalfBandwidths=2` means the target frequency interval is [58,62] Hz, **not** a 2-Hz total bandwidth. BLASST uses flanking comparison bands (approximately 54-56 and 64-66 Hz for the 60-Hz target). The test frequencies must fit inside Nyquist.


### GUI references and automatic boundary handling (2026-11-17)

The settings dialog has seven editable numeric/text settings, a Serial/Parallel selector, and an Optimized/Legacy implementation selector. Under a static plain-text **Reference** heading are Ball et al. (2017) and Maruyama et al. (2026). Neither citation is an editable input field. This GUI revision has **not** yet been run in MATLAB in the authoring environment.

**Boundary events are now supported automatically:** `pop_blasst_standalone` reads continuous EEGLAB `EEG.event` entries of type `boundary` (case-insensitive). For latency K+0.5, it cuts after sample K. Boundary markers at 0.5 and `EEG.pnts+0.5`, and repeated markers, do not create empty segments. Each contiguous interval is BLASST-processed independently, with no Gabor atoms fitted across a boundary. The plugin keeps the original number/order of samples, existing events and their latencies, and data dimensions. Epoched trials are processed separately as before.

**Policy A (approved):** Any contiguous interval shorter than `max(8*round(ScaleSeconds*Fs)+1, round(10*Fs))` samples is passed through **bit-for-bit unchanged**, and the plugin emits one `BLASST:ShortSegments` warning that states the skipped segment count and sample percentage. A 4-s scale at 250 Hz requires 8,001 samples (~32.004 s). This threshold is a **conservative implementation restriction**, not a theoretical BLASST limit. The scale is never silently shortened. If every interval is too short, BLASST returns the entire dataset unchanged **with a warning**, not a processing-success claim.

For audit, the function returns `report` and stores the same fields in `EEG.etc.blasst_standalone`, including `boundaryEventCount`, `boundaryCuts`, `minimumSamplesRequired`, `continuousSegmentRanges`, `processedSegmentRanges`, `skippedSegmentRanges`, `processedSegmentCount`, `skippedSegmentCount`, `skippedSampleCount`, `skippedSampleFraction` (0–1), and `acceptedIterationsByContinuousSegment`. The aggregate `acceptedIterations` uses the maximum across processed contiguous intervals. Processing is **not** mathematically identical to fitting BLASST to a discontinuous concatenation, nor to finite `SegmentSeconds` mode. See `BOUNDARY_HANDLING_20261117.md`.

Standalone matrix callers may specify the sample indices directly using `'BoundaryCuts',[100 500]` (cut after samples 100 and 500). The EEGLAB `pop_` entry point infers these automatically from `EEG.event`; no new GUI setting is required. Records with invalid/out-of-range boundary latencies are rejected instead of silently moving a discontinuity.

## Channel-by-channel progress (alpha UX update, November 17, 2026)

- The EEGLAB `pop_blasst_standalone` entry point enables `ShowProgress=true` by default. After **each selected channel is fully processed across all boundary-separated continuous intervals**, it prints `BLASST 1/34 (4.7 s) ...` in the MATLAB Command Window, with that channel's processing seconds, cumulative elapsed seconds, and the summed accepted-iteration counts. A MATLAB Desktop `waitbar` displays the same completed-channel progress. Closing that window does **not** cancel the analysis.
- The standalone numerical entry point defaults to `ShowProgress=false` to allow silent programmatic/batch execution. Either entry point accepts `'ShowProgress',true|false`. The EEGLAB command history records this choice.
- Progress counts selected channels (or channel/trial pairs for epoched inputs), **not** segments or internal BLASST atom iterations. For one continuous record with 34 selected channels, the denominator is 34 regardless of how many `boundary` events occur.
- The report contains `channelElapsedSeconds` (channels x trials, NaN for excluded channels), `channelAcceptedAtomCounts` (summed accepted-iteration counts over boundary intervals and target frequencies), `completedChannelTrials`, `showProgress`, and `elapsedSeconds`. The iteration counts are a diagnostic, not a new convergence measure; in experimental finite `SegmentSeconds` mode, each interval's value is an aggregation of per-core counts as documented in the numerical provenance.
- The processing order was changed from interval-major to channel-major **only to make completed-channel status truthful**. Channels are independently fitted; BLASST filtering, stopping, defaults, and boundary rules were not changed. The added `test_blasst_progress` asserts numerical output equality with the progress flag on/off and checks the two channel completion messages. **This test has not been executed on MATLAB yet.**
- Alpha user's estimated wall time on 2026-11-17: approximately 160 seconds for a 600-second, 34-channel, 256-Hz record (real-time factor about 0.267), before this progress update. This is a manual estimate; the fraction skipped due to short boundary-separated intervals is still unknown, so it is not a calibrated throughput benchmark.

## Numerical provenance

This is **not** a verbatim copy of the current PREP pipeline. The inner BLASST algorithm is adapted into separate MATLAB functions, and the published paper's PREP wrapper parameter handling has not been validated against this adaptation. All methods-affecting functions live in distinct `.m` files inside the `+blasstcore` package. No nested MATLAB functions and no Python signal processing.

- A public PREP `blasstLineNoise.m` passes the option name `'MaximumIterations'` to `blasst`, while the latter recognizes `'MaxIterations'`. Thus the requested 10 may have resulted in the lower-level default of 50. On the same public revision, `blasst.m` tests for a variable named `scaleBases` instead of `scale`, causing a supplied `Scale` to be overwritten by `4*samplingRate`. The published simulation's intended 4-s scale coincides with that default. **These observations apply to the inspected public files, not necessarily to the locally modified source used by the paper.**
- v0.1.0-dev defaults to 50 iterations to reproduce the lower-level public-source default. The user can request 10 explicitly, but this is not claimed to reproduce the published results until historical source and output are checked.
- `SegmentSeconds=Inf` fits each **continuous interval** in full (or the entire record if there are no boundaries), closest to the original on that interval, at considerable computational cost.
- Finite `SegmentSeconds` fits extended context windows and retains the interior. Its per-window coefficient distributions and stopping conditions are different from whole-record BLASST. It is experimental; NOT validated against the manuscript results, and changes at segment boundaries are possible. The report records this mode.
- EEGLAB continuous `boundary` events now split input into truly continuous intervals. Intervals below the documented minimum are left exactly unchanged and counted; each genuine epoched trial is separately processed. Do not interpret omitted intervals as successfully filtered.
- NaN and Inf are rejected, rather than silently repaired. Exactly constant channels are passed through unchanged. The input numeric type and data dimensions are preserved.
- The addon does not automatically estimate line frequency, does not automatically remove harmonics, does not resample, does not change reference, and does not interpolate channels.

## Validated environment and results (2026-11-17)

ChatGPT Work tested the preceding candidate on Windows 11 with MATLAB R2024b Update 3 (`24.2.0.2806996`) and EEGLAB 2024.0. `test_blasst_smoke`, `test_blasst_validation`, `test_blasst_segments` (bookkeeping only), `test_blasst_quality_metrics` (diagnostic only), `test_blasst_eeglab`, and `test_blasst_legacy_parity` passed. The full-record algorithm matched a pinned public PREP `blasst.m` on the parity-test waveform to relative L2 error `5.28061548092e-16`. EEGLAB Tools menu, prior GUI execution and Cancel, explicit command-history replay, and type and channel preservation were also checked. The then-current code intentionally rejected boundaries. **Those results precede the present boundary-aware implementation and the static-reference GUI revision.**

**Important limits:** These tests do not demonstrate parity with the code that created the figures in Maruyama et al. (2026). The user-provided validation report explicitly states that the published-study source revision and MATLAB path precedence are unknown. In the diagnostic burst test (which used 0.5-s scale), burst-period RMSE fell from `0.818650` to `0.472376`, but there was no predefined scientifically acceptable target-preservation threshold. Finite-segment processing has only bookkeeping validation, not scientific validation.

The exact original work report is retained in `docs/VALIDATION_REPORT_20261117.md`. For the historical source audit, see `docs/SOURCE_AUDIT_20261117.md` and the optional, **untested** `tests/test_blasst_historical_wrapper_parity.m` diagnostic.

## Testing before use

1. Open the validated combination MATLAB R2024b Update 3 with EEGLAB 2024.0, or validate another combination independently (the minimum supported versions have not been established). Record `version`, `ver`, `which -all eeglab`, `which -all pop_blasst_standalone`, `which -all blasst`, and `which -all pop_blasst`.
2. Add the plugin distribution root to the MATLAB path, without `genpath` over every EEGLAB component.
3. Run `test_blasst_smoke`, `test_blasst_validation`, `test_blasst_segments`, `test_blasst_quality_metrics`, `test_blasst_boundary` (new), `test_blasst_progress` (new), `test_blasst_eeglab`, and `test_blasst_boundary_eeglab` (new; the tests folder needs to be on the path). Run `test_blasst_legacy_parity` only with the pinned reference source on the MATLAB path.
4. Locate the **actual historical** `BLASST_PREPpipeline` folder used by the manuscript; the paper's analysis script indicates a relative path but does not include the source. Run `test_blasst_historical_wrapper_parity(PATH)` only after inspecting the folder and `which -all` resolution. This optional diagnostic compares the historical wrapper with candidate maximum-iteration settings of 10 and 50 and does not claim a pass/fail for publication. Keep a copy or fingerprint of all relevant source files. An absent source or mismatch remains a blocker.
5. In EEGLAB GUI, ensure the Tools menu appears only once, the citations are uneditable plain text, the dialog accepts valid values, `Cancel` does nothing, events and metadata are preserved, the returned command replays exactly, and saved data reload. Exercise datasets with multiple boundaries (including short, duplicated, start and end boundaries) and verify the skipped percentage.
6. Compare the continuous mode with the existing BLASST output for an identical deidentified test dataset, preserving preprocessing and every parameter. Inspect both the PSD around 60 Hz and waveforms around true 60-Hz bursts.
7. Benchmark 1, 19, and 128 channels with at least 5 minutes when feasible; separately evaluate finite-segment mode for seam discontinuities and signal-preservation errors, not just PSD flattening.
8. Do not release to the EEGLAB catalog or publish to GitHub without an explicit decision by Makoto after numerical and licensing review.

## References and source

- Ball KR, Hairston WD, Franaszczuk PJ, Robbins KA. BLASST: Band Limited Atomic Sampling With Spectral Tuning With Applications to Utility Line Noise Filtering. *IEEE Transactions on Biomedical Engineering*. 2017;64(9):2276-2287. DOI: 10.1109/TBME.2016.2632119. PMID: 27893379.
- Maruyama Y et al. Comparing line-noise removal algorithms for EEG data processing. *Cortex*. 2026; available online November 7, 2026; Journal Pre-proof (volume/pages not yet assigned at the time of this review). DOI: 10.1016/j.cortex.2026.11.005. https://doi.org/10.1016/j.cortex.2026.11.005
- Inspected PREP source revision: `VisLab/EEG-Clean-Tools` Git commit `0914132081ea7d534ee19f96973791fd81825755`, paths `PrepPipeline/utilities/blasst/blasst.m`, `blasst_internal.m`, `blasst_test.m`, and `PrepPipeline/utilities/blasstLineNoise.m`. The source location, commit, file hashes, and limits of validation are documented in PROVENANCE.md and SOURCE_AUDIT_20261117.md.
- The original BLASST algorithm files explicitly bear Kenneth Ball's 2015 copyright and an Apache License 2.0 header. Adapted implementation retains attribution and carries Apache-2.0 license text. The broader PREP repository contains GPL-licensed components that are **not included** in this candidate. Do a final per-file licensing check before publication.

## Not part of an analysis pipeline

The distribution ZIP is an installable EEGLAB extension, not a layout for a computational research-analysis repository. The separate workbench ZIP follows Makoto's `code/lib`, `code/tests`, `code/docs` structure; no stage scripts or handmade data were placed in p-numbered output directories.

### Progress-bar time estimate (alpha UX)

The EEGLAB progress bar estimates time remaining in **minutes** from the
median elapsed time of completed channels multiplied by the remaining
channel count (or channel/trial count for epoched data). The estimate starts
after the first channel and is recalculated at every completion. This
does not change the BLASST signal-processing algorithm.


## Channel-parallel execution (v0.2.0-dev, not yet MATLAB-tested)

The GUI offers **Execution mode: Serial / Parallel**. Parallel is the initial
GUI selection if Parallel Computing Toolbox is installed and its license is
available, but the numerical API defaults to Serial for backward compatibility.
Use the exact same parameter set for both modes. Typical script calls:

```matlab
[serial,~,rs] = blasst_standalone(data,256, ...
    'LineFrequencies',60,'HalfBandwidths',2,'ScaleSeconds',4, ...
    'MaxIterations',50,'SegmentSeconds',Inf,'ExecutionMode','serial');
[parallel,~,rp] = blasst_standalone(data,256, ...
    'LineFrequencies',60,'HalfBandwidths',2,'ScaleSeconds',4, ...
    'MaxIterations',50,'SegmentSeconds',Inf,'ExecutionMode','parallel');
assert(isequal(serial,parallel));
```

Each `parfor` iteration computes **one entire channel of one trial**,
including all its continuous intervals and preserved short segments. No
BLASST atom iteration is itself parallelized. Outputs are restored by
original channel index; parallel completion order never changes EEG order.

The worker calls `send(queue, struct(...))` on completing a channel.
`parallel.pool.DataQueue` notifies the MATLAB client, where `afterEach`
updates `ProgressTracker`, a waitbar (if enabled), and the command window.
No worker accesses GUI graphics. If `W` is the number of actual pool workers,
the approximate remaining time in **minutes** after `k` channel/trial
completions out of `N` total is `median(t_1,...,t_k)*(N-k)/(60*W)`.
The estimate can jump early in the run; it excludes the elapsed duration
of in-flight work and potential worker imbalance, and is an **estimate**,
not a bound. The per-completion history is stored in
`report.remainingMinutesByCompletion` and
`report.channelByCompletion`. ETA is calculated from runtime metadata
only and does not influence the fit.

`report.poolStartupSeconds` separates the initialization/check of a pool
from `report.processingElapsedSeconds` (the `parfor` computation and final
progress draining). `report.elapsedSeconds` spans both operations. For a fair
Serial/Parallel comparison, reuse an established pool or report startup
separately, keep identical channel/sample/Boundary settings, and collect
repeat runs. MATLAB can have its own internal FFT multithreading, so
speedup is not necessarily `W`-fold.

**Tests not yet executed in MATLAB:**
`test_blasst_eta_parallel` (pool-independent ETA arithmetic), and
`test_blasst_parallel` (exact serial vs parallel output and Boundary
parity; skips cleanly if the Parallel Computing Toolbox is unavailable).
The prior Windows validation report predates this parallel branch.

**Installation:** Remove or rename the older
`BLASST_Standalone_0.1.0-dev` plugin folder before installing
`BLASST_Standalone_0.3.1-dev` under EEGLAB `plugins/`. Do not leave two
versions with the same `eegplugin_blasst_standalone` entry point on the
MATLAB path. Restart MATLAB/EEGLAB and verify `which -all blasst_standalone`.


## v0.3.1-dev GUI progress adjustment (November 17, 2026)

Both Legacy and Optimized now use one explicitly drawn waitbar, including
eligible boundary-interval updates for single-channel records. The old
full-record >5-minute advisory warning was removed; the short-boundary
warning remains. See `docs/PROGRESS_GUI_20261117.md`. The core fitting
algorithms are unchanged. MATLAB desktop regression remains required.
