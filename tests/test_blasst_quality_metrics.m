function metrics = test_blasst_quality_metrics()
%TEST_BLASST_QUALITY_METRICS Ground-truth burst/noise RMSE diagnostic.
% Deliberately prints measurements instead of inventing pass thresholds.
% SPDX-License-Identifier: Apache-2.0
rng(1349,'twister');
fs = 250;
t = (0:4999)/fs;
frequency = 60+0.05*sin(2*pi*t/16);
phase = 2*pi*cumsum(frequency)/fs;
line = (1+0.25*sin(2*pi*t/9)).*sin(phase);
truth = 1.5*exp(-0.5*((t-10)/0.18).^2).*sin(2*pi*60*t+0.4);
white = 0.04*randn(size(t));
contaminated = truth+line+white;
[clean,~,report] = blasst_standalone(contaminated,fs, ...
    'LineFrequencies',60,'HalfBandwidths',2,'ScaleSeconds',0.5, ...
    'MaxIterations',4,'Resolution',2);
% Following the paper, white noise is subtracted before comparing against
% the ground-truth target waveform. Partition is not an exact attribution
% of distortion and remaining interference for data-dependent algorithms.
burst = abs(t-10) <= 0.54;
peri = abs(t-10) > 0.54 & abs(t-10) <= 1.29;
noSignal = abs(t-10) > 1.29;
beforeError = contaminated-white-truth;
afterError = clean-white-truth;
metrics = struct();
metrics.before = [sqrt(mean(beforeError(burst).^2)), ...
    sqrt(mean(beforeError(peri).^2)),sqrt(mean(beforeError(noSignal).^2))];
metrics.after = [sqrt(mean(afterError(burst).^2)), ...
    sqrt(mean(afterError(peri).^2)),sqrt(mean(afterError(noSignal).^2))];
metrics.acceptedIterations = report.acceptedIterations;
metrics.elapsedSeconds = report.elapsedSeconds;
assert(all(isfinite(metrics.after)));
assert(all(isfinite(metrics.before)));
fprintf('Ground-truth RMSE [burst peri no-signal]\n');
fprintf('Before: %.6f %.6f %.6f\n',metrics.before);
fprintf('After : %.6f %.6f %.6f\n',metrics.after);
fprintf('No pass threshold imposed: interpret signal preservation and rejection separately.\n');
end
