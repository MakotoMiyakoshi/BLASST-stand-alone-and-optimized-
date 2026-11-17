function test_blasst_boundary_eeglab()
%TEST_BLASST_BOUNDARY_EEGLAB EEGLAB event positions, metadata and replay.
% Requires EEGLAB on MATLAB path.
% SPDX-License-Identifier: Apache-2.0
if exist('eeg_emptyset','file') ~= 2
    error('BLASST:EEGLABMissing','EEGLAB is required for this test.');
end
rng(20261117,'twister');
fs = 250;
N = 12500;
EEG = eeg_emptyset();
EEG.srate = fs;
EEG.nbchan = 2;
EEG.pnts = N;
EEG.trials = 1;
EEG.data = single(randn(2,N));
EEG.xmin = 0;
EEG.xmax = (N-1)/fs;
EEG.event = struct('type',{'boundary','boundary','stim','boundary', ...
    'boundary','boundary','boundary'}, ...
    'latency',{0.5,250.5,2000,4100.5,4100.5,8800.5,12500.5}, ...
    'duration',{0,0,0,0,0,0,0});
opts = {'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'Resolution',2,'MaxIterations',1,'Channels',1};
preTypes = {EEG.event.type};
preLatencies = [EEG.event.latency];
initialInput = EEG;
[out,com,report] = pop_blasst_standalone(EEG,opts{:});
assert(isequal(report.boundaryCuts,[250 4100 8800]));
assert(isequal(out.data(:,1:250),EEG.data(:,1:250)));
assert(isequal(size(out.data),size(EEG.data)) && out.pnts == EEG.pnts);
assert(isequal({out.event.type},preTypes));
assert(isequal([out.event.latency],preLatencies));
assert(report.skippedSegmentCount == 1 && report.skippedSampleFraction == 250/N);
assert(contains(com,'pop_blasst_standalone'));
assert(report.completedChannelTrials == 1);
assert(report.showProgress);
% Replay the generated command against the untouched original dataset.
EEG = initialInput;
eval(com);
assert(isequal(EEG.data,out.data));
assert(isequal([EEG.event.latency],[out.event.latency]));
fprintf('PASS test_blasst_boundary_eeglab (events, short span, history)\n');
end
