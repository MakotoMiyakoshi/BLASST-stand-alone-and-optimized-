function test_blasst_progress()
%TEST_BLASST_PROGRESS Progress text and timing are non-algorithmic.
% Verifies exact output equality with and without progress reporting.
% SPDX-License-Identifier: Apache-2.0
rng(20261117,'twister');
fs = 250;
N = 7000;
t = (0:N-1)/fs;
data = single([sin(2*pi*60*t)+0.1*randn(1,N); randn(1,N); zeros(1,N)]);
opts = {'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'Resolution',2,'MaxIterations',1, ...
    'Channels',[1 2 3],'BoundaryCuts',2500};
[noProgress,removedOff,reportOff] = blasst_standalone(data,fs,opts{:}, ...
    'ShowProgress',false);
textOutput = evalc(['[withProgress,removedOn,reportOn] = ' ...
    'blasst_standalone(data,fs,opts{:},''ShowProgress'',true);']);
assert(isequal(noProgress,withProgress));
assert(isequal(removedOff,removedOn));
assert(isequal(reportOff.acceptedIterations,reportOn.acceptedIterations));
assert(isequal(reportOff.acceptedIterationsByContinuousSegment, ...
    reportOn.acceptedIterationsByContinuousSegment));
assert(contains(textOutput,'BLASST 1/3 ('));
assert(contains(textOutput,'BLASST 2/3 ('));
assert(contains(textOutput,'BLASST 3/3 ('));
assert(all(isfinite(reportOn.channelElapsedSeconds(:))));
assert(all(reportOn.channelElapsedSeconds(:) >= 0));
assert(reportOn.completedChannelTrials == 3);
% The progress-bar ETA is median(completed channel times) * remaining / 60.
for completed = 1:3
    expectedMinutes = median(reportOn.channelElapsedSeconds(1:completed)) * ...
        (3-completed)/60;
    measuredMinutes = reportOn.remainingMinutesByCompletion(completed);
    assert(abs(expectedMinutes-measuredMinutes) < ...
        1e-12*max(1,abs(expectedMinutes)));
end
assert(reportOn.remainingMinutesByCompletion(end) == 0);
assert(isequal(size(reportOff.remainingMinutesByCompletion),[1 3]));
assert(reportOn.channelAcceptedAtomCounts(1) >= 0);
assert(~reportOff.showProgress && reportOn.showProgress);
fprintf('PASS test_blasst_progress (channel counts and numerical identity)\n');
end
