function test_blasst_progress_both_implementations()
%TEST_BLASST_PROGRESS_BOTH_IMPLEMENTATIONS Verify numerical invariance.
% Run with this plugin folder and its tests folder on the MATLAB path.
% The desktop waitbar itself also needs manual visual verification.
% SPDX-License-Identifier: Apache-2.0
rng(20261117,'twister');
fs = 250;
N = 12000;
t = (0:N-1)/fs;
x = single(sin(2*pi*60*t) + 0.03*randn(1,N));
opts = {'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'Resolution',2,'MaxIterations',1, ...
    'BoundaryCuts',[4000 8000],'Channels',1,'ExecutionMode','serial'};
impls = {'legacy','optimized'};
for k = 1:numel(impls)
    name = impls{k};
    [quietClean,quietRemoved,quietReport] = blasst_standalone( ...
        x,fs,opts{:},'Implementation',name,'ShowProgress',false);
    textOutput = evalc(['[shownClean,shownRemoved,shownReport] = ' ...
        'blasst_standalone(x,fs,opts{:},''Implementation'',name,''ShowProgress'',true);']);
    assert(isequal(quietClean,shownClean));
    assert(isequal(quietRemoved,shownRemoved));
    assert(isequal(quietReport.acceptedIterations,shownReport.acceptedIterations));
    assert(isequal(quietReport.acceptedIterationsByContinuousSegment, ...
        shownReport.acceptedIterationsByContinuousSegment));
    assert(shownReport.totalEligibleIntervals == 3);
    assert(shownReport.completedEligibleIntervals == 3);
    assert(shownReport.totalEligibleSamplesForProgress == N);
    assert(shownReport.processedEligibleSamplesForProgress == N);
    assert(quietReport.completedEligibleIntervals == 0);
    assert(contains(textOutput,['implementation ' name]));
    assert(contains(textOutput,'BLASST 1/1 ('));
    assert(~contains(textOutput,'Full-record BLASST on more than 5 minutes'));
    fprintf('PASS %s: 3 interval notifications and identical numerical output\n',name);
end
% Verify the long-record warning was removed without executing the kernel.
% Constant data take the existing no-fitting fast path.
longConstant = zeros(1,300*fs+1,'single');
lastwarn('');
[unchanged,removed,report] = blasst_standalone(longConstant,fs, ...
    'LineFrequencies',60,'ScaleSeconds',0.5,'MaxIterations',1, ...
    'ShowProgress',false,'Implementation','optimized');
[~,warnId] = lastwarn;
assert(~strcmp(warnId,'BLASST:Slow'));
assert(isequal(unchanged,longConstant));
assert(all(removed == 0));
assert(report.completedChannelTrials == 1);
fprintf('PASS long-record advisory removed; constant-data output unchanged\n');
end
