# BLASST alpha UX: channel-level progress — 2026-11-17

## Requirement

For a continuous EEG with 34 selected channels, report each completed channel as `1/34 (x.x s)`, `2/34 (x.x s)`, and so forth. If boundaries split the input, count a channel as completed **only after all of its eligible continuous intervals finish**. Store the elapsed times and per-channel accepted-iteration summaries.

## Implementation

- `blasst_standalone.m`: a `ShowProgress` logical name/value parameter (off by default for the standalone API); outer loop on `channel`, inner loop on each non-skipped continuous interval; one text status per completed channel, plus a lightweight waitbar if MATLAB Desktop graphics are available. The waitbar displays `Estimated remaining: X.X min`, not elapsed time. After each completed channel/trial, compute `median(observed channel durations in seconds) * (total channel/trials - completed) / 60`. No ETA is shown until the first channel completes.
- `pop_blasst_standalone.m`: default `ShowProgress=true` for EEGLAB GUI/script use; preserve the option in the generated history command. Pass `ShowProgress=false` to disable both outputs for batch work.
- `report`: `showProgress`, `channelElapsedSeconds`, `channelAcceptedAtomCounts`, `completedChannelTrials`, `remainingMinutesByCompletion` in addition to previous accepted-iteration arrays and timing.
- No changes to the numerical atom selection, fit, or stopping criterion; no change to BoundaryCuts or short-span policy A. A waitbar closure does not cancel filtering; errors close it.

## Display example (illustrative, not measured)

```text
BLASST: 34 selected channel(s), 1 trial(s), 3 continuous interval(s)
BLASST 1/34 (4.7 s)  ch 1, trial 1; total 4.7 s; accepted iterations 6
BLASST 2/34 (5.1 s)  ch 2, trial 1; total 9.8 s; accepted iterations 5
...
BLASST 34/34 (3.9 s)  ch 34, trial 1; total 160.0 s; accepted iterations 4
```

## Validation gates

Run `test_blasst_progress` with MATLAB, and rerun the existing boundary, EEGLAB, and public-PREP parity tests. The test checks that filtering with progress on/off is byte-for-byte identical and the status count is correct. Verify waitbar GUI behavior, interruption/closure, and history replay on Windows 11 with EEGLAB 2024.0. **Code has been statically inspected; no new MATLAB execution has been performed in this environment.**

## Estimated remaining time (new UX requirement)

The waitbar initially reads `BLASST: estimating remaining time...`. After
each completed channel it displays, for example, `5/34 | Estimated remaining: 2.3 min`.
The estimate uses the median elapsed time of **all completed channel/trials**
and multiplies by the remaining number. The last entry is `0.0 min`.
The Command Window retains the previously requested elapsed time per channel
in seconds for diagnostics. No data-processing parameters or Boundary handling
are changed. Actual completion times may deviate from the estimate.

Validation: `test_blasst_progress` now checks the ETA formula after each of
three completed channels and that the filtered samples with `ShowProgress`
true and false are identical. GUI waitbar visual verification on Windows
MATLAB is still pending.
