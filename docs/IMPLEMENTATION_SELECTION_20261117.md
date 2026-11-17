# BLASST Standalone v0.3.0-dev — Dual implementation staging

## Source hierarchy

- `+blasstcore/` **legacy**: unmodified copies of all 14 files from
  `BLASST_Standalone_0.2.0-dev_parallel.zip`. This is a PREP-derived adapted
  implementation, not byte-exact public PREP or Ken Ball original.
- `+blasstoptACH/` **optimized**: unmodified copy of the separately
  validated experimental package `+blasstoptACH.zip`.
- `+blasstdispatch/`: new routing for optimized channel/segment calculations.
  For legacy, its channel wrapper delegates directly to the preexisting
  `blasstcore.denoiseChannel`. All boundary policy remains at the top level.

## User controls

The GUI has **Optimized BLASST (default)** and **Legacy BLASST
(PREP-derived adapted port)**. An explicit MATLAB API call is:

```matlab
[EEG,com,report] = pop_blasst_standalone(EEG, ...
    'Implementation','legacy','ExecutionMode','serial', ...
    'LineFrequencies',50,'HalfBandwidths',2, ...
    'ScaleSeconds',4,'Resolution',2,'MaxIterations',50);
```

`'Implementation','optimized'` is assumed if omitted. The processing
report contains `implementationRequested` and `implementationUsed`; the
EEGLAB command-history string includes the explicit implementation.

## Staging and test instructions

1. Preserve the currently installed plugin. Unpack the staging folder as
   a separate directory; do **not** overwrite the installed plugin before
   successful tests. EEGLAB should see only one active `eegplugin_blasst_standalone.m`
   on its path, so launch the staging test in a separate MATLAB session.
2. Run `tests/test_blasst_implementation_switch.m`,
   `tests/test_blasst_implementation_eeglab.m`,
   `tests/test_blasst_implementation_parallel.m` if PCT is installed, plus
   the existing plugin tests.
3. Verify the GUI default, switch to legacy, and use Cancel. Confirm the
   command string replays the selected implementation.
4. Test real EEGLAB boundary events and `.set` save/load, including actual
   30-minute EEG with discontinuities, skipped short segments, multiple
   line-frequency settings, selected channels, and epoched input.
5. Repeat performance tests on the integrated plugin, distinguishing
   pool startup, processing time, and full EEGLAB wall time.
6. Release only after checks are complete. Keep the exact original/PREP
   source separate and pinned for any future *byte-exact* reference mode.

## Known limitations

- Staging build has not executed MATLAB or EEGLAB in the container.
- `compatibleHist` was equivalence-tested in MATLAB R2024b; other versions
  need independent bin-edge validation.
- The previous plugin's parallel mode starts/reuses the default MATLAB pool.
  This staging change does not force the benchmark's 8x2 configuration.
- Bounded filter FFT cache is per worker, up to 768 MiB each.
- Legacy port and optimized core are distinct implementations of BLASST;
  numerical equivalence was established only under tested configurations.
