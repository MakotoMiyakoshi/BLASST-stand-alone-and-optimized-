function [clean, removed, report] = blasst_standalone(data, srate, varargin)
%BLASST_STANDALONE Channel-wise BLASST line-noise removal.
%   [CLEAN, REMOVED, REPORT] = BLASST_STANDALONE(DATA, SRATE, ...)
%   DATA: channels x samples x trials, real numeric EEG.
%
%   Name/value options:
%     'LineFrequencies'   target frequency in Hz (default 60)
%     'HalfBandwidths'    target search half-width in Hz (default 2)
%     'ScaleSeconds'      Gabor scale in seconds (default 4)
%     'Resolution'        Gabor placement density, integer (default 2)
%     'MaxIterations'     upper bound per channel/frequency (default 50)
%     'Channels'          channel indices (default all)
%     'SegmentSeconds'    finite core segment length, or Inf for legacy
%                         full-record processing (default Inf)
%     'BoundaryCuts'      sample indices immediately BEFORE discontinuities;
%                         segments shorter than the minimum remain unchanged
%     'ExecutionMode'    'serial' (default) or 'parallel' (requires PCT)
%     'Implementation'   'optimized' (default) or 'legacy' (PREP-derived port)
%     'ShowProgress'      print each completed channel (default false);
%                         interactive waitbar shows boundary-interval progress
%                         (when available) and estimated remaining time;
%                         channel-level ETA is retained in the report
%
%   This is a traceable reimplementation of Kenneth Ball's 2015 BLASST
%   source, with separate functions for methods-affecting operations.
%   The legacy mode retains the existing PREP-derived adapted port without
%   changing any legacy +blasstcore functions. The optimized mode is a
%   separate implementation in +blasstoptACH (FFT smooth7 / A / C / H).
%   Legacy is NOT a byte-exact copy of the original PREP source.
%   See docs/PROVENANCE.md. Original BLASST files: Apache-2.0.
%   Modified implementation (C) 2026, BLASST Standalone contributors.
%   SPDX-License-Identifier: Apache-2.0

if ~(isnumeric(data) && isfloat(data) && isreal(data) && (ndims(data) == 2 || ndims(data) == 3))
    error('BLASST:Input', 'DATA must be a real single/double channels-by-samples(-by-trials) array.');
end
if isempty(data) || size(data,2) < 2
    error('BLASST:Input', 'At least two samples are required.');
end
if ~(isscalar(srate) && isnumeric(srate) && isfinite(srate) && srate > 0)
    error('BLASST:Input', 'SRATE must be a positive finite scalar.');
end
if any(~isfinite(data(:)))
    error('BLASST:Input', 'Input contains NaN or Inf; BLASST does not impute or remove these samples.');
end

p = inputParser;
p.FunctionName = 'blasst_standalone';
p.addParameter('LineFrequencies', 60, @(v) isnumeric(v) && isreal(v) && isvector(v) && ~isempty(v));
p.addParameter('HalfBandwidths', 2, @(v) isnumeric(v) && isreal(v) && isvector(v) && ~isempty(v));
p.addParameter('ScaleSeconds', 4, @(v) isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v > 0);
p.addParameter('Resolution', 2, @(v) isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v >= 1 && fix(v) == v);
p.addParameter('MaxIterations', 50, @(v) isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v >= 1 && fix(v) == v);
p.addParameter('Channels', 1:size(data,1), @(v) isnumeric(v) && isreal(v) && isvector(v));
p.addParameter('SegmentSeconds', Inf, @(v) isnumeric(v) && isscalar(v) && ((isinf(v) && v > 0) || (isfinite(v) && v > 0)));
p.addParameter('BoundaryCuts', [], @(v) isnumeric(v) && isreal(v) && ...
    (isempty(v) || isvector(v)));
p.addParameter('ShowProgress', false, @(v) islogical(v) && isscalar(v));
p.addParameter('ExecutionMode', 'serial', @(v) (ischar(v) || ...
    (isstring(v) && isscalar(v))) && ...
    any(strcmpi(char(v),{'serial','parallel'})));
p.addParameter('Implementation', 'optimized', @(v) (ischar(v) || ...
    (isstring(v) && isscalar(v))) && ...
    any(strcmpi(char(v),{'optimized','legacy'})));
p.addParameter('BoundaryEventCount', 0, @(v) isnumeric(v) && ...
    isscalar(v) && isfinite(v) && v >= 0 && fix(v) == v);
p.parse(varargin{:});
a = p.Results;
frequencies = a.LineFrequencies(:)';
widths = a.HalfBandwidths(:)';
if numel(widths) == 1
    widths = repmat(widths, size(frequencies));
end
if numel(widths) ~= numel(frequencies) || any(~isfinite(widths)) || any(widths <= 0) ...
        || any(~isfinite(frequencies)) || any(frequencies <= 0)
    error('BLASST:Parameters', 'Frequency centers and positive half-widths must match.');
end
if any(frequencies + 3*widths >= srate/2) || any(frequencies - 3*widths <= 0)
    error('BLASST:Parameters', 'Target and flanking test bands must fit strictly inside (0, Nyquist).');
end
channels = a.Channels(:)';
if any(channels < 1) || any(channels > size(data,1)) || ...
        any(fix(channels) ~= channels) || numel(unique(channels)) ~= numel(channels)
    error('BLASST:Parameters', 'Channels must be unique valid integer indices.');
end
scaleSamples = round(a.ScaleSeconds*srate);
if scaleSamples < 2
    error('BLASST:Parameters', 'Gabor scale must contain at least two samples.');
end
% Four full Gabor half-widths of context around each segment ensure that
% the atom support of the retained interior is entirely observed.
minSamples = max(8*scaleSamples + 1, round(10*srate));
% BoundaryCuts are integer sample indices: a cut after sample K gives
% non-overlapping intervals [..K] and [K+1..]. EEGLAB event latencies
% (typically K+0.5) are converted separately by blasstcore.boundaryCuts.
N = size(data,2);
cuts = double(a.BoundaryCuts(:)');
if any(~isfinite(cuts)) || any(fix(cuts) ~= cuts) || ...
        any(cuts < 1) || any(cuts >= N)
    error('BLASST:BoundaryCuts', ...
        'BoundaryCuts must be integer interior sample indices in [1, N-1].');
end
cuts = unique(cuts);
if ~isempty(cuts) && size(data,3) ~= 1
    error('BLASST:BoundaryCuts', ...
        'BoundaryCuts are supported only for continuous (one-trial) data.');
end
starts = [1 cuts+1];
ends = [cuts N];
segmentLengths = ends-starts+1;
skippedMask = segmentLengths < minSamples;
if isempty(cuts) && a.BoundaryEventCount == 0 && any(skippedMask)
    error('BLASST:ShortRecording', ...
        'At least %d samples (%.3f seconds) required at scale %.3f seconds.', ...
        minSamples, minSamples/srate, a.ScaleSeconds);
end
if (~isempty(cuts) || a.BoundaryEventCount > 0) && any(skippedMask)
    warning('BLASST:ShortSegments', ...
        ['BLASST: %d/%d boundary-separated segments are shorter than %d samples ', ...
         '(%.3f s). Leaving %d/%d samples (%.2f%%) unchanged.'], ...
        nnz(skippedMask),numel(starts),minSamples,minSamples/srate, ...
        sum(segmentLengths(skippedMask)),N, ...
        100*sum(segmentLengths(skippedMask))/N);
end

if isfinite(a.SegmentSeconds)
    segmentSamples = floor(a.SegmentSeconds*srate);
    if segmentSamples < minSamples
        error('BLASST:Parameters', 'SegmentSeconds must span at least %.3f seconds.', minSamples/srate);
    end
else
    segmentSamples = Inf;
end

% The scientific operation is channel-independent. Both execution modes
% call precisely the same per-channel function, so scheduling cannot change
% the BLASST frequency fit, stop rule, or boundary handling.
clean = data;
removed = zeros(size(data), 'like', data);
ntrials = size(data,3);
iterationCounts = zeros(size(data,1), numel(frequencies), ntrials);
iterationsBySegment = zeros(size(data,1), numel(frequencies), numel(starts), ntrials);
channelElapsedSeconds = nan(size(data,1), ntrials);
channelAcceptedAtomCounts = zeros(size(data,1), ntrials);
channelTrialTotal = numel(channels)*ntrials;
activeSegments = find(~skippedMask);
executionMode = lower(char(a.ExecutionMode));
implementation = lower(char(a.Implementation));
workerCount = 1;
poolStartupSeconds = 0;
ticOverall = tic;

% Creating a pool is intentionally explicit: serial users never need PCT.
% Reuse an existing pool, otherwise honor MATLAB's default pool profile.
if strcmp(executionMode,'parallel')
    if ~blasstcore.hasParallelToolbox()
        error('BLASST:ParallelUnavailable', ...
            ['Parallel execution requires a licensed MATLAB Parallel Computing ', ...
             'Toolbox. Choose Serial in the plugin dialog.']);
    end
    ticPool = tic;
    pool = gcp('nocreate');
    if isempty(pool)
        if a.ShowProgress
            fprintf('BLASST: starting default MATLAB parallel pool...\n');
        end
        try
            pool = parpool;
        catch ME
            error('BLASST:ParallelPool', ...
                'Could not start MATLAB parallel pool: %s',ME.message);
        end
    end
    poolStartupSeconds = toc(ticPool);
    workerCount = pool.NumWorkers;
    if a.ShowProgress
        fprintf('BLASST: parallel mode using %d worker(s).\n',workerCount);
    end
end

ticProcessing = tic;
progress = blasstdispatch.ProgressTracker(channelTrialTotal,workerCount, ...
    a.ShowProgress,ticProcessing,executionMode, ...
    segmentLengths(activeSegments),implementation);
cleanupProgress = onCleanup(@() progress.close()); %#ok<NASGU>
% Announce algorithm provenance even when the caller disables progress.
% The numerical reference named 'Original' in EEG.etc is the preserved
% legacy PREP-derived port, not a byte-exact historical source file.
if strcmp(implementation,'optimized')
    displayImplementation = 'Optimized';
else
    displayImplementation = 'Original (Legacy PREP-derived port)';
end
fprintf('BLASST: implementation %s [%s]; %d selected channel(s), %d trial(s), %d continuous interval(s); mode %s\n', ...
    implementation,displayImplementation,numel(channels),ntrials, ...
    numel(starts),executionMode);

if strcmp(executionMode,'serial')
    for trial = 1:ntrials
        for channel = channels
            ticChannel = tic;
            if a.ShowProgress && ~isempty(activeSegments)
                % Client-side UI update after each boundary interval.
                notifySegment = @(seg,seconds,samples) progress.recordSegment( ...
                    struct('channel',channel,'trial',trial,'segment',seg, ...
                    'seconds',seconds,'samples',samples));
            else
                notifySegment = [];
            end
            [channelClean,channelRemoved,counts,countsBySegment] = ...
                blasstdispatch.denoiseChannel(data(channel,:,trial), ...
                starts,ends,activeSegments,frequencies,widths,srate, ...
                scaleSamples,a.Resolution,a.MaxIterations,segmentSamples, ...
                implementation,notifySegment);
            clean(channel,:,trial) = channelClean;
            removed(channel,:,trial) = channelRemoved;
            iterationCounts(channel,:,trial) = counts;
            iterationsBySegment(channel,:,:,trial) = ...
                reshape(countsBySegment,[1 numel(frequencies) numel(starts)]);
            elapsed = toc(ticChannel);
            channelElapsedSeconds(channel,trial) = elapsed;
            atomCount = sum(countsBySegment(:));
            channelAcceptedAtomCounts(channel,trial) = atomCount;
            progress.record(struct('channel',channel,'trial',trial, ...
                'seconds',elapsed,'acceptedAtoms',atomCount));
        end
    end
else
    % DataQueue callbacks execute on the MATLAB client, never on workers.
    % All GUI calls, median ETA, and log output therefore stay client-side.
    queue = parallel.pool.DataQueue;
    afterEach(queue,@(message) progress.record(message));
    for trial = 1:ntrials
        numberSelected = numel(channels);
        % Explicitly slice selected rows for parfor worker distribution.
        trialSelectedData = data(channels,:,trial);
        cleanCells = cell(1,numberSelected);
        removedCells = cell(1,numberSelected);
        countCells = cell(1,numberSelected);
        segmentCountCells = cell(1,numberSelected);
        elapsedCells = zeros(1,numberSelected);
        atomCells = zeros(1,numberSelected);
        parfor selectedIndex = 1:numberSelected
            channel = channels(selectedIndex);
            ticChannel = tic;
            if a.ShowProgress && ~isempty(activeSegments)
                % Workers send short progress messages; GUI stays on client.
                notifySegment = @(seg,seconds,samples) send(queue, ...
                    struct('kind','segment','channel',channel,'trial',trial, ...
                    'segment',seg,'seconds',seconds,'samples',samples));
            else
                notifySegment = [];
            end
            [localClean,localRemoved,localCounts,localBySegment] = ...
                blasstdispatch.denoiseChannel( ...
                trialSelectedData(selectedIndex,:),starts,ends, ...
                activeSegments,frequencies,widths,srate,scaleSamples, ...
                a.Resolution,a.MaxIterations,segmentSamples, ...
                implementation,notifySegment);
            localElapsed = toc(ticChannel);
            localAtoms = sum(localBySegment(:));
            cleanCells{selectedIndex} = localClean;
            removedCells{selectedIndex} = localRemoved;
            countCells{selectedIndex} = localCounts;
            segmentCountCells{selectedIndex} = localBySegment;
            elapsedCells(selectedIndex) = localElapsed;
            atomCells(selectedIndex) = localAtoms;
            send(queue,struct('channel',channel,'trial',trial, ...
                'seconds',localElapsed,'acceptedAtoms',localAtoms));
        end
        % Restore outputs to their ORIGINAL channel indices, independent
        % of worker completion order.
        for selectedIndex = 1:numberSelected
            channel = channels(selectedIndex);
            clean(channel,:,trial) = cleanCells{selectedIndex};
            removed(channel,:,trial) = removedCells{selectedIndex};
            iterationCounts(channel,:,trial) = countCells{selectedIndex};
            iterationsBySegment(channel,:,:,trial) = ...
                reshape(segmentCountCells{selectedIndex}, ...
                [1 numel(frequencies) numel(starts)]);
            channelElapsedSeconds(channel,trial) = elapsedCells(selectedIndex);
            channelAcceptedAtomCounts(channel,trial) = atomCells(selectedIndex);
        end
        % Flush queued client-side DataQueue callbacks after each trial.
        drawnow;
    end
    % DataQueue notifications are asynchronous. Allow a bounded flush;
    % never let delayed GUI messages change or block numerical results.
    ticDrain = tic;
    while progress.Completed < channelTrialTotal && toc(ticDrain) < 3
        drawnow;
        pause(0.01);
    end
    if progress.Completed < channelTrialTotal
        warning('BLASST:ProgressIncomplete', ...
            '%d/%d asynchronous progress messages received; numerical output is complete.', ...
            progress.Completed,channelTrialTotal);
    end
end
processingElapsedSeconds = toc(ticProcessing);
report = struct('version', '1.0.0', 'algorithm', 'Ball BLASST', ...
    'implementationRequested', implementation, ...
    'implementationUsed', implementation, ...
    'implementationLineage', 'PREP-derived adapted legacy or optimized ACH', ...
    'legacySourceFamily', 'VisLab/EEG-Clean-Tools PREP BLASST 0914132 (adapted port, not byte-exact)', ...
    'optimizedSourceFamily', 'BLASST Standalone 7-smooth + selected atom + filter FFT cache + compatible histogram', ...
    'srate', srate, 'lineFrequencies', frequencies, 'halfBandwidths', widths, ...
    'scaleSecondsRequested', a.ScaleSeconds, 'scaleSamplesUsed', scaleSamples, ...
    'inputParameters', a, 'defaultedParameters', {p.UsingDefaults}, ...
    'segmentSamplesUsed', segmentSamples, ...
    'inputClass', class(data), 'inputSize', [size(data,1) N ntrials], ...
    'resolution', a.Resolution, 'maxIterations', a.MaxIterations, ...
    'channels', channels, 'segmentSeconds', a.SegmentSeconds, ...
    'segmentedMode', isfinite(a.SegmentSeconds), ...
    'segmentedIterationsAreMaximumAcrossSegments', ...
        isfinite(a.SegmentSeconds) || ~isempty(cuts), ...
    'boundaryMode', a.BoundaryEventCount > 0 || ~isempty(cuts), ...
    'boundaryEventCount', a.BoundaryEventCount, 'boundaryCuts', cuts, ...
    'minimumSamplesRequired', minSamples, ...
    'continuousSegmentRanges', [starts(:) ends(:)], ...
    'skippedSegmentRanges', [starts(skippedMask)' ends(skippedMask)'], ...
    'processedSegmentRanges', [starts(~skippedMask)' ends(~skippedMask)'], ...
    'segmentLengthsSamples', segmentLengths, ...
    'processedSegmentCount', nnz(~skippedMask), ...
    'skippedSegmentCount', nnz(skippedMask), ...
    'skippedSampleCount', sum(segmentLengths(skippedMask)), ...
    'skippedSampleFraction', sum(segmentLengths(skippedMask))/N, ...
    'acceptedIterations', iterationCounts, ...
    'acceptedIterationsByContinuousSegment', iterationsBySegment, ...
    'showProgress', a.ShowProgress, ...
    'executionModeRequested', executionMode, ...
    'executionModeUsed', executionMode, ...
    'parallelWorkerCount', workerCount, ...
    'poolStartupSeconds', poolStartupSeconds, ...
    'processingElapsedSeconds', processingElapsedSeconds, ...
    'channelElapsedSeconds', channelElapsedSeconds, ...
    'remainingMinutesByCompletion', progress.RemainingMinutesByCompletion, ...
    'completedEligibleIntervals', progress.CompletedSegments, ...
    'totalEligibleIntervals', progress.TotalSegments, ...
    'processedEligibleSamplesForProgress', progress.CompletedSamples, ...
    'totalEligibleSamplesForProgress', progress.TotalSamples, ...
    'channelByCompletion', progress.ChannelByCompletion, ...
    'trialByCompletion', progress.TrialByCompletion, ...
    'channelAcceptedAtomCounts', channelAcceptedAtomCounts, ...
    'completedChannelTrials', channelTrialTotal, ...
    'progressMessagesReceived', progress.Completed, ...
    'elapsedSeconds', toc(ticOverall));
end
