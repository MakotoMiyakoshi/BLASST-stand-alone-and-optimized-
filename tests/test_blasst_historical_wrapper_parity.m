function metrics = test_blasst_historical_wrapper_parity(historicalFolder)
%TEST_BLASST_HISTORICAL_WRAPPER_PARITY Read-only synthetic-source comparison.
%   METRICS = TEST_BLASST_HISTORICAL_WRAPPER_PARITY(HISTORICALFOLDER)
%   HISTORICALFOLDER must contain blasstLineNoise.m and a blasst/
%   subfolder containing blasst.m, blasst_internal.m, blasst_test.m.
%
%   Compares a known synthetic waveform against the exact historical PREP
%   wrapper with the caller parameters used in the Cortex study. Also tests
%   candidate MaxIterations=10 and MaxIterations=50. This is diagnostic;
%   matching here does NOT establish scientific parity on the study data.
%   Historical files are read, not modified. All MATLAB path changes are
%   temporary and are restored even after an error.
%
%   This test has NOT yet been executed in MATLAB (created 2026-11-17).
%   SPDX-License-Identifier: Apache-2.0

if nargin ~= 1 || ~(ischar(historicalFolder) || (isstring(historicalFolder) && isscalar(historicalFolder)))
    error('BLASST:HistoricalSource', 'Supply the actual historical BLASST_PREPpipeline folder.');
end
historicalFolder = char(historicalFolder);
coreFolder = fullfile(historicalFolder,'blasst');
expectedFiles = {fullfile(historicalFolder,'blasstLineNoise.m'), ...
    fullfile(coreFolder,'blasst.m'),fullfile(coreFolder,'blasst_internal.m'), ...
    fullfile(coreFolder,'blasst_test.m')};
for idx = 1:numel(expectedFiles)
    if exist(expectedFiles{idx},'file') ~= 2
        error('BLASST:HistoricalSource', 'Historical source missing: %s',expectedFiles{idx});
    end
end

originalPath = path;
restorePath = onCleanup(@() path(originalPath)); %#ok<NASGU>
addpath(historicalFolder,'-begin');
addpath(coreFolder,'-begin');
functionNames = {'blasstLineNoise','blasst','blasst_internal','blasst_test'};
for idx = 1:numel(functionNames)
    selected = which(functionNames{idx});
    fprintf('%s => %s\n',functionNames{idx},selected);
    % compare paths case-insensitively on Windows (and exactly on Linux)
    if ~strcmpi(selected,expectedFiles{idx})
        error('BLASST:HistoricalSource', ...
            'Unresolved path precedence for %s; refuse ambiguous comparison.',functionNames{idx});
    end
end

fs = 250;
rng(20261117,'twister');
t = (0:8499)/fs; % 34 seconds; sufficient for 4-second Gabor scale
frequency = 60+0.05*sin(2*pi*t/16);
phase = 2*pi*cumsum(frequency)/fs;
line = (1+0.25*sin(2*pi*t/9)).*sin(phase);
burst = 1.5*exp(-0.5*((t-17)/0.18).^2).*sin(2*pi*60*t+0.4);
raw = line+burst+0.04*randn(size(t));

signal = struct('data',double(raw),'srate',fs);
lineNoiseIn = struct('lineNoiseChannels',1, 'Fs',fs, ...
    'lineFrequencies',60,'fScanBandWidth',2, ...
    'maximumIterations',10,'scale',4*fs);
reference = blasstLineNoise(signal,lineNoiseIn);
[actual10,~,report10] = blasst_standalone(raw,fs, ...
    'LineFrequencies',60,'HalfBandwidths',2,'ScaleSeconds',4, ...
    'Resolution',2,'MaxIterations',10,'SegmentSeconds',Inf);
[actual50,~,report50] = blasst_standalone(raw,fs, ...
    'LineFrequencies',60,'HalfBandwidths',2,'ScaleSeconds',4, ...
    'Resolution',2,'MaxIterations',50,'SegmentSeconds',Inf);
ref = double(reference.data(:));
metrics = struct();
metrics.referenceFunctions = functionNames;
metrics.referenceFiles = expectedFiles;
metrics.maxIterationsRequestedByPaperWrapper = 10;
metrics.relativeL2vs10 = norm(ref-double(actual10(:)))/max(1,norm(ref));
metrics.relativeL2vs50 = norm(ref-double(actual50(:)))/max(1,norm(ref));
metrics.maxAbsVs10 = max(abs(ref-double(actual10(:))));
metrics.maxAbsVs50 = max(abs(ref-double(actual50(:))));
metrics.acceptedIterations10 = report10.acceptedIterations;
metrics.acceptedIterations50 = report50.acceptedIterations;
fprintf('Historical wrapper vs candidate max=10: relative L2 %.12g, max abs %.12g\n', ...
    metrics.relativeL2vs10, metrics.maxAbsVs10);
fprintf('Historical wrapper vs candidate max=50: relative L2 %.12g, max abs %.12g\n', ...
    metrics.relativeL2vs50, metrics.maxAbsVs50);
fprintf('Candidate accepted passes: max10=%d, max50=%d\n', ...
    max(report10.acceptedIterations(:)),max(report50.acceptedIterations(:)));
fprintf('Diagnostic only. No paper parity or waveform-preservation PASS asserted.\n');
end
