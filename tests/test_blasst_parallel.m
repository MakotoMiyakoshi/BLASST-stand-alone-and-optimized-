function test_blasst_parallel()
%TEST_BLASST_PARALLEL Exact serial/parallel agreement, including boundaries.
% No background execution and no modification of research pipeline outputs.
% SPDX-License-Identifier: Apache-2.0
if ~blasstcore.hasParallelToolbox()
    fprintf('SKIP test_blasst_parallel (Parallel Computing Toolbox unavailable)\n');
    return
end
rng(20261117,'twister');
fs = 250;
N = 9200;
t = (0:N-1)/fs;
x = single([sin(2*pi*60*t) + 0.05*randn(1,N); ...
    0.2*randn(1,N); cos(2*pi*60*t)+0.1*randn(1,N); zeros(1,N)]);
opts = {'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'Resolution',2,'MaxIterations',1, ...
    'Channels',[1 3 4],'BoundaryCuts',[3000 6100], ...
    'ShowProgress',false};
[serialClean,serialRemoved,serialReport] = blasst_standalone( ...
    x,fs,opts{:},'ExecutionMode','serial');
[parallelClean,parallelRemoved,parallelReport] = blasst_standalone( ...
    x,fs,opts{:},'ExecutionMode','parallel');
assert(isequal(serialClean,parallelClean));
assert(isequal(serialRemoved,parallelRemoved));
assert(isequal(parallelClean(2,:),x(2,:))); % excluded channel unchanged
assert(isequal(serialReport.acceptedIterations,parallelReport.acceptedIterations));
assert(isequal(serialReport.acceptedIterationsByContinuousSegment, ...
    parallelReport.acceptedIterationsByContinuousSegment));
assert(parallelReport.parallelWorkerCount >= 1);
assert(strcmp(parallelReport.executionModeUsed,'parallel'));
assert(strcmp(serialReport.executionModeUsed,'serial'));
assert(parallelReport.completedChannelTrials == 3);
assert(parallelReport.progressMessagesReceived == 3);
assert(all(isfinite(parallelReport.channelElapsedSeconds([1 3 4]))));
assert(isnan(parallelReport.channelElapsedSeconds(2)));
assert(isequal(sort(parallelReport.channelByCompletion),[1 3 4]));
assert(parallelReport.remainingMinutesByCompletion(end) == 0);
assert(all(parallelReport.remainingMinutesByCompletion(1:2) >= 0));
assert(serialReport.parallelWorkerCount == 1);
assert(serialReport.poolStartupSeconds == 0);
assert(parallelReport.poolStartupSeconds >= 0);
assert(parallelReport.processingElapsedSeconds >= 0);
fprintf('PASS test_blasst_parallel: output parity and completion tracking\n');
end
