function test_blasst_smoke()
%TEST_BLASST_SMOKE Deterministic no-toolbox smoke and invariance test.
% SPDX-License-Identifier: Apache-2.0
rng(7812,'twister');
fs = 250;
t = (0:4999)/fs;
line = 4*sin(2*pi*60*t);
target = 0.8*exp(-0.5*((t-9)/0.18).^2).*sin(2*pi*60*t+pi/3);
raw = single([line+target+0.04*randn(size(t)); 0.03*randn(size(t))]);
[clean,removed,report] = blasst_standalone(raw,fs, ...
    'LineFrequencies',60,'HalfBandwidths',2,'ScaleSeconds',1, ...
    'MaxIterations',2,'Resolution',2,'Channels',1);
assert(isequal(size(clean),size(raw)));
assert(isequal(class(clean),class(raw)));
assert(isequal(raw(2,:),clean(2,:))); % Excluded channel strictly untouched.
assert(all(isfinite(clean(:))) && all(isfinite(removed(:))));
assert(max(abs(double(raw(1,:))-double(clean(1,:))-double(removed(1,:)))) < 2e-5);
assert(report.scaleSamplesUsed == fs);
assert(report.maxIterations == 2);
assert(isequal(report.channels,1));
fprintf('PASS test_blasst_smoke (%.3fs, iterations=%d)\n', ...
    report.elapsedSeconds,report.acceptedIterations(1));
end
