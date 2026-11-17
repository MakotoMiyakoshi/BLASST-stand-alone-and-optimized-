function test_blasst_validation()
%TEST_BLASST_VALIDATION Check errors, dimensions, and epoch preservation.
% SPDX-License-Identifier: Apache-2.0
rng(81,'twister');
fs = 250;
raw = reshape(0.03*randn(1,3000*2),1,3000,2);
[clean,removed,report] = blasst_standalone(raw,fs, ...
    'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'MaxIterations',1);
assert(isequal(size(clean),size(raw)));
assert(isequal(size(removed),size(raw)));
assert(isequal(size(report.acceptedIterations),[1 1 2]));
assert(max(abs(raw(:)-clean(:)-removed(:))) < 1e-9);
failed = false;
try
    blasst_standalone([1 NaN 2],250);
catch ME
    failed = strcmp(ME.identifier,'BLASST:Input');
end
assert(failed,'NaN must be rejected.');
failed = false;
try
    blasst_standalone(raw,250,'LineFrequencies',124,'HalfBandwidths',2);
catch ME
    failed = strcmp(ME.identifier,'BLASST:Parameters');
end
assert(failed,'Invalid Nyquist settings must be rejected.');
fprintf('PASS test_blasst_validation\n');
end
