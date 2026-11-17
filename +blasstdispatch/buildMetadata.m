function metadata = buildMetadata(report, EEG, command)
%BUILDMETADATA Preserve BLASST method parameters and processing provenance.
%   The source EEG is the UNPROCESSED input to the current BLASST call.
%   Numerical kernels are not modified by this logging function.
%   To reproduce the results, use the original input samples and the same
%   implementation and effective settings.  The cleaned dataset alone
%   cannot recover the original input samples.
% SPDX-License-Identifier: Apache-2.0

if strcmp(report.implementationUsed,'optimized')
    displayVersion = 'Optimized';
    sourceDescription = report.optimizedSourceFamily;
elseif strcmp(report.implementationUsed,'legacy')
    displayVersion = 'Original';
    sourceDescription = report.legacySourceFamily;
else
    error('BLASST:Implementation', ...
        'Unexpected BLASST implementation: %s',report.implementationUsed);
end

% Direct, predictable fields for typical EEGLAB/Methods queries.
metadata = struct();
metadata.version = displayVersion; % Requested values: 'Optimized'/'Original'.
metadata.pluginVersion = report.version;
metadata.algorithm = report.algorithm;
metadata.implementation = report.implementationUsed;
metadata.implementationSource = sourceDescription;
metadata.legacyIsAdaptedPREPPort = true;
metadata.samplingRate = report.srate;
metadata.lineFrequencies = report.lineFrequencies;
metadata.halfBandwidths = report.halfBandwidths;
metadata.scaleSeconds = report.scaleSecondsRequested;
metadata.scaleSamples = report.scaleSamplesUsed;
metadata.resolution = report.resolution;
metadata.maxIterations = report.maxIterations;
metadata.channels = report.channels;
metadata.segmentSeconds = report.segmentSeconds;
metadata.segmentSamples = report.segmentSamplesUsed;
metadata.showProgress = report.showProgress;
metadata.executionMode = report.executionModeUsed;
metadata.parallelWorkerCount = report.parallelWorkerCount;
metadata.boundaryCuts = report.boundaryCuts;
metadata.boundaryEventCount = report.boundaryEventCount;
metadata.minimumSamplesRequired = report.minimumSamplesRequired;
metadata.continuousSegmentRanges = report.continuousSegmentRanges;
metadata.processedSegmentRanges = report.processedSegmentRanges;
metadata.skippedSegmentRanges = report.skippedSegmentRanges;
metadata.skippedSampleCount = report.skippedSampleCount;
metadata.acceptedIterations = report.acceptedIterations;
metadata.acceptedIterationsByContinuousSegment = ...
    report.acceptedIterationsByContinuousSegment;
metadata.processingElapsedSeconds = report.processingElapsedSeconds;
metadata.poolStartupSeconds = report.poolStartupSeconds;

% inputParameters records every parsed name/value option of the core,
% including defaults and wrapper-derived BoundaryCuts/BoundaryEventCount.
% The effective values separately show normalized bandwidths, the rounded
% Gabor scale and segmentation thresholds actually used in computation.
metadata.inputParameters = report.inputParameters;
metadata.defaultedParameters = report.defaultedParameters;
metadata.effectiveParameters = struct( ...
    'LineFrequencies',report.lineFrequencies, ...
    'HalfBandwidths',report.halfBandwidths, ...
    'ScaleSeconds',report.scaleSecondsRequested, ...
    'ScaleSamples',report.scaleSamplesUsed, ...
    'Resolution',report.resolution, ...
    'MaxIterations',report.maxIterations, ...
    'Channels',report.channels, ...
    'SegmentSeconds',report.segmentSeconds, ...
    'SegmentSamples',report.segmentSamplesUsed, ...
    'ShowProgress',report.showProgress, ...
    'ExecutionMode',report.executionModeUsed, ...
    'Implementation',report.implementationUsed, ...
    'BoundaryCuts',report.boundaryCuts, ...
    'BoundaryEventCount',report.boundaryEventCount, ...
    'MinimumSamplesRequired',report.minimumSamplesRequired);

% Explicit core replay arguments also preserve observed boundary cuts even
% if the EEG.event array is subsequently changed. Call, for example:
% [clean,removed,report] = blasst_standalone(originalEEG.data, ...
%     originalEEG.srate,EEG.etc.BLASST.coreReplayArguments{:});
metadata.coreReplayArguments = { ...
    'LineFrequencies',report.lineFrequencies, ...
    'HalfBandwidths',report.halfBandwidths, ...
    'ScaleSeconds',report.scaleSecondsRequested, ...
    'Resolution',report.resolution, ...
    'MaxIterations',report.maxIterations, ...
    'Channels',report.channels, ...
    'SegmentSeconds',report.segmentSeconds, ...
    'ShowProgress',report.showProgress, ...
    'ExecutionMode',report.executionModeUsed, ...
    'Implementation',report.implementationUsed, ...
    'BoundaryCuts',report.boundaryCuts, ...
    'BoundaryEventCount',report.boundaryEventCount};
metadata.replayCommand = command;
metadata.replayRequiresOriginalInput = true;

% Input identification is intentionally shallow: do not embed a second
% copy of the raw EEG into EEG.etc or increase .set size unnecessarily.
source = struct();
source.size = report.inputSize;
source.class = report.inputClass;
source.samplingRate = report.srate;
for k = {'setname','filename','filepath','subject','session','condition','group'}
    field = k{1};
    if isfield(EEG,field)
        source.(field) = EEG.(field);
    end
end
metadata.inputDataset = source;
metadata.matlabVersion = version;
metadata.computer = computer;
end
