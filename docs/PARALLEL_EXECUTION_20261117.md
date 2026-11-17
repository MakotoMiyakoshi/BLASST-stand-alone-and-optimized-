# Parallel support and alpha acceptance protocol — 2026-11-17

Status: source implementation / static checks only. No MATLAB execution
of this v0.2.0-dev branch has occurred in the authoring environment.

- `ExecutionMode=serial` is the unchanged channel-wise scheduling baseline.
- `ExecutionMode=parallel` uses `parfor` over channels and `DataQueue`
  notifications to the MATLAB client. Progress events may arrive out of order.
- ETA (min) is median completed channel time in seconds times the number
  remaining divided by actual pool worker count and 60. This is approximate.
- `poolStartupSeconds` is recorded separately from processing time.
- Serial/parallel must be compared on identical arrays, frequency options,
  Gabor scale, iteration limit, Boundary cuts and channel selection.
- Both modes call one `blasstcore.denoiseChannel` implementation; there is
  no numerical dependency on GUI/ETA or message delivery ordering.
- `parfor` is historically present in Kay Robbins' publicly available
  `VisLab/EEG-Clean-Tools/PrepPipeline/utilities/blasstLineNoise.m`,
  reference git commit 0914132081ea7d534ee19f96973791fd81825755.
- Existing short-interval skip and boundary safety rules are unchanged.
- Run `test_blasst_eta_parallel` and `test_blasst_parallel` before any
  inference about research readiness. Compare serial and parallel in
  both whole-record and boundary-aware modes with real input.
- MATLAB Parallel Computing Toolbox is optional: Serial works without it.
- Do not interpret the warning for very long records as recommending the
  mathematically distinct, unvalidated finite-segmentation mode.
