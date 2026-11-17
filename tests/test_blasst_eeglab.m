function test_blasst_eeglab()
%TEST_BLASST_EEGLAB Deterministic EEGLAB structure smoke test.
% Requires EEGLAB installed and in MATLAB path.
% SPDX-License-Identifier: Apache-2.0
if exist('eeg_emptyset','file') ~= 2
    error('BLASST:EEGLABMissing', 'EEGLAB is needed for this test.');
end
rng(123,'twister');
fs = 250;
EEG = eeg_emptyset();
EEG.srate = fs;
EEG.nbchan = 2;
EEG.pnts = 4000;
EEG.trials = 1;
EEG.data = single(randn(2,4000));
EEG.xmin = 0;
EEG.xmax = (EEG.pnts-1)/fs;
[processed,com,report] = pop_blasst_standalone(EEG, ...
    'LineFrequencies',60,'HalfBandwidths',2,'ScaleSeconds',0.5, ...
    'MaxIterations',1,'Channels',1);
assert(isequal(size(processed.data),size(EEG.data)));
assert(isequal(processed.data(2,:),EEG.data(2,:)));
assert(contains(com,'pop_blasst_standalone'));
assert(report.scaleSamplesUsed == 125);
assert(isfield(processed.etc,'blasst_standalone'));
assert(report.showProgress);
assert(contains(com,'''ShowProgress'''));
assert(report.completedChannelTrials == 1);
fprintf('PASS test_blasst_eeglab\n');
end
