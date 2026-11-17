function test_blasst_etc_metadata()
%TEST_BLASST_ETC_METADATA Both implementations persist complete parameters.
%   Run after adding the plugin directory to the MATLAB path.  When EEGLAB
%   is installed, include it on the path so eeg_checkset is exercised.
% SPDX-License-Identifier: Apache-2.0
rng(20261117,'twister');
fs = 256;
N = 7200;
t = (0:N-1)/fs;
raw = single(0.5*sin(2*pi*50*t)+0.04*randn(1,N));
if exist('eeg_emptyset','file') == 2
    EEG = eeg_emptyset();
else
    EEG = struct();
end
EEG.data = raw;
EEG.srate = fs;
EEG.nbchan = 1;
EEG.trials = 1;
EEG.pnts = N;
EEG.xmin = 0;
EEG.xmax = (N-1)/fs;
EEG.setname = 'BLASST metadata fixture';
EEG.event = struct('type','boundary','latency',3600.5,'duration',0);
opts = {'LineFrequencies',50,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'Resolution',2,'MaxIterations',2, ...
    'Channels',1,'SegmentSeconds',Inf,'ExecutionMode','serial', ...
    'ShowProgress',false};
implementations = {'optimized','legacy'};
versions = {'Optimized','Original'};
for k = 1:numel(implementations)
    [output,command,rep] = pop_blasst_standalone(EEG,opts{:}, ...
        'Implementation',implementations{k});
    assert(isfield(output.etc,'BLASST'));
    meta = output.etc.BLASST;
    assert(strcmp(meta.version,versions{k}));
    assert(strcmp(meta.pluginVersion,'1.0.0'));
    assert(strcmp(meta.implementation,implementations{k}));
    assert(strcmp(meta.executionMode,'serial'));
    assert(strcmp(meta.inputParameters.Implementation,implementations{k}));
    assert(strcmp(meta.effectiveParameters.Implementation,implementations{k}));
    assert(isequal(meta.inputParameters.BoundaryCuts,3600));
    assert(isequal(meta.boundaryCuts,3600));
    assert(meta.boundaryEventCount == 1);
    assert(isequal(meta.inputDataset.size,[1 N 1]));
    assert(isequal(meta.inputDataset.class,'single'));
    assert(isequal(meta.lineFrequencies,50));
    assert(isequal(meta.halfBandwidths,2));
    assert(meta.scaleSeconds == 0.5 && meta.scaleSamples == 128);
    assert(meta.maxIterations == 2);
    assert(meta.minimumSamplesRequired == 2560);
    assert(isinf(meta.segmentSeconds));
    assert(isequal(meta.acceptedIterations,rep.acceptedIterations));
    assert(strcmp(meta.replayCommand,command));
    assert(contains(command,implementations{k}));
    % Direct core replay against ORIGINAL input, preserving exact cuts.
    [replay,~,replayedReport] = blasst_standalone( ...
        EEG.data,EEG.srate,meta.coreReplayArguments{:});
    assert(isequal(replay,output.data));
    assert(isequal(replayedReport.acceptedIterations,rep.acceptedIterations));
    assert(isfield(output.etc,'blasst_standalone'));
end

% The omitted Implementation option must choose Optimized by default.
[defaultOutput,~,defaultReport] = pop_blasst_standalone(EEG,opts{:});
assert(strcmp(defaultOutput.etc.BLASST.version,'Optimized'));
assert(strcmp(defaultReport.implementationUsed,'optimized'));

fprintf('PASS metadata: Original/Optimized, effective inputs, boundaries, replay.\n');
end
