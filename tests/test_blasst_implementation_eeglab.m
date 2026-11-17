function test_blasst_implementation_eeglab()
%TEST_BLASST_IMPLEMENTATION_EEGLAB GUI/API replay includes implementation.
if exist('eeg_emptyset','file') ~= 2
    error('BLASST:EEGLABMissing','This test needs EEGLAB on MATLAB path.');
end
rng(117,'twister');
fs=250; N=10000; t=(0:N-1)/fs;
EEG=eeg_emptyset();
EEG.data=single([cos(2*pi*60*t)+0.04*randn(1,N); ...
    0.1*randn(1,N)]);
EEG.srate=fs;
EEG.nbchan=2;
EEG.trials=1;
EEG.pnts=N;
EEG.xmin=0;
EEG.xmax=(N-1)/fs;
EEG.event=struct('type','boundary','latency',5000.5,'duration',0);
options={'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'MaxIterations',2,'ShowProgress',false, ...
    'ExecutionMode','serial'};
[Elegacy,comLegacy,repLegacy]=pop_blasst_standalone(EEG,options{:}, ...
    'Implementation','legacy');
[Eopt,comOpt,repOpt]=pop_blasst_standalone(EEG,options{:}, ...
    'Implementation','optimized');
assert(strcmp(repLegacy.implementationUsed,'legacy'));
assert(strcmp(repOpt.implementationUsed,'optimized'));
assert(~isempty(strfind(comLegacy,'''Implementation'',''legacy''')));
assert(~isempty(strfind(comOpt,'''Implementation'',''optimized''')));
assert(isequal(repLegacy.boundaryCuts,5000));
assert(isequal(repOpt.boundaryCuts,5000));
assert(isequal(repLegacy.acceptedIterations,repOpt.acceptedIterations));
err=norm(double(Elegacy.data(:))-double(Eopt.data(:)))/ ...
    max(norm(double(Elegacy.data(:))),eps);
assert(err<=1e-12);
assert(strcmp(Elegacy.etc.blasst_standalone.implementationUsed,'legacy'));
fprintf('PASS EEG wrapper implementation selector and history command.\n');
end
