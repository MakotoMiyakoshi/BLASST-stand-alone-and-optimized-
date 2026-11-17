function test_blasst_legacy_parity()
%TEST_BLASST_LEGACY_PARITY Reference code is REQUIRED; no silent skip.
% Place the unmodified pinned PREP blasst.m / blasst_internal.m /
% blasst_test.m on the MATLAB path BEFORE executing this function.
% Our namespaced core does not shadow these original function names.
% SPDX-License-Identifier: Apache-2.0
if exist('blasst','file') ~= 2 || exist('blasst_internal','file') ~= 2 || ...
        exist('blasst_test','file') ~= 2
    error('BLASST:ReferenceMissing', 'Pinned legacy source is required for parity test.');
end
rng(4201,'twister');
fs = 250;
t = (0:8499)/fs;
raw = sin(2*pi*60*t)+0.05*randn(size(t));
scaleSeconds = 4;
iterations = 2;
reference = blasst(raw,60,2,fs,'Scale',fs*scaleSeconds, ...
    'Resolution',2,'MaxIterations',iterations,'Verbose',0);
actual = blasst_standalone(raw,fs,'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',scaleSeconds,'Resolution',2,'MaxIterations',iterations);
relativeError = norm(double(actual(:))-double(reference(:)))/max(1,norm(double(reference(:))));
fprintf('Legacy parity relative L2 error: %.12g\n',relativeError);
assert(relativeError < 1e-10,'BLASST adapter does not reproduce pinned legacy algorithm.');
end
