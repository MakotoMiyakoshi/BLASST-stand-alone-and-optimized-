function test_blasst_segments()
%TEST_BLASST_SEGMENTS Verify experimental segmentation bookkeeping only.
% This test does not validate scientific equivalence with full-record BLASST.
% SPDX-License-Identifier: Apache-2.0
rng(617,'twister');
fs = 250;
t = (0:7499)/fs;
raw = 2*sin(2*pi*60*t)+0.05*randn(size(t));
[clean,removed,report] = blasst_standalone(raw,fs, ...
    'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'MaxIterations',1, 'SegmentSeconds',12);
assert(isequal(size(clean),size(raw)));
assert(isequal(size(removed),size(raw)));
assert(all(isfinite(clean)));
assert(max(abs(raw-clean-removed)) < 1e-9);
assert(report.segmentedMode);
assert(report.segmentedIterationsAreMaximumAcrossSegments);
fprintf('PASS test_blasst_segments (segmented mode NOT parity-validated)\n');
end
