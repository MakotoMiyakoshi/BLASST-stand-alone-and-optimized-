# BLASST progress popup consistency (v0.3.1-dev)

## What changed

- Both **Optimized** and **Legacy (PREP-derived)** use a single client-side
  `blasstdispatch.ProgressTracker` waitbar. The GUI is explicitly drawn before
  processing starts, so an optimized 1-channel run does not finish before the
  window first paints.
- For EEG recordings with `boundary` events, the same popup advances after
  each **eligible continuous interval** (including an eligible constant interval
  that requires no fit), even when only one channel is selected. Skipped
  intervals remain unchanged and do not count as attempted work.
- The progress fraction is based on eligible samples completed, not on raw
  accepted-iteration counts. Remaining time is estimated from elapsed worker
  seconds per processed sample; the estimate may vary with segment difficulty.
- Both Serial and Parallel use the same tracker. Parallel workers only send
  small notification messages through `parallel.pool.DataQueue`; all GUI calls
  execute on the MATLAB client.
- The existing per-channel completion text and median-based ETA in the
  MATLAB Command Window remain unchanged. The report now includes
  `completedEligibleIntervals`, `totalEligibleIntervals`, and eligible-sample
  progress counts.
- The obsolete `BLASST:Slow` full-record advisory was removed. The
  scientifically meaningful `BLASST:ShortSegments` warning is retained.
- `ShowProgress=false` remains available for headless MATLAB batch jobs.
  Closing the waitbar does not cancel BLASST.

## Scientific code integrity

All 14 files in the legacy `+blasstcore` folder are byte-for-byte unchanged
from v0.3.0-dev; all eight files of the validated `+blasstoptACH` package
are also unchanged. Only the non-scientific dispatcher, progress display,
entry-point logging, and test documentation changed.

The dispatcher now uses the same per-interval scheduling loop for legacy
and optimized, selecting the unmodified `blasstcore.denoiseRecord` / legacy
segmented wrapper or the unmodified optimized core as requested. Exact
legacy parity is explicitly tested against the untouched
`blasstcore.denoiseChannel` wrapper.

## Windows MATLAB R2024b acceptance test

1. Put the **staging** v0.3.1-dev plugin folder on the MATLAB path, without
   overwriting the installed plugin until these tests pass. Check
   `which -all pop_blasst_standalone` for conflicts.
2. Run `test_blasst_progress_both_implementations`,
   `test_blasst_progress_tracker_intervals`,
   `test_blasst_implementation_switch`, and the existing EEGLAB and Parallel
   regression tests.
3. On the user's 3780-second, 1-channel dataset with 11 boundary intervals,
   run both implementations with `ShowProgress=true`. The popup must appear
   promptly for both, report intervals and ETA, and close after completion.
   The two short intervals must still be passed through unchanged.
4. Repeat one Parallel run using multiple selected channels. Confirm the
   waitbar updates on the client and that both cores produce numerically
   matching outputs and accepted iterations.
5. Verify `eegh()` reproduces the selection correctly; test with both modes.

**Validation status:** Static integrity checks are available here. MATLAB
and EEGLAB desktop tests have NOT been executed in the authoring environment.
