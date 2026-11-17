function [channelClean,channelRemoved,counts,countsBySegment] = denoiseChannel( ...
    channelData,starts,ends,activeSegments,frequencies,widths,fs,scale, ...
    resolution,maxIterations,segmentSamples,implementation,segmentCallback)
%DENOISECHANNEL Select legacy or optimized implementation per channel.
%  Legacy calls the original, untouched +blasstcore numerical kernels.
%  Both modes apply identical boundary intervals and skipped-segment rules.
% One computational path for serial and parallel scheduling. Untouched
% intervals and the original sample order are preserved without interpolation.
% SPDX-License-Identifier: Apache-2.0
if nargin < 13
    segmentCallback = [];
end
if ~strcmp(implementation,'legacy') && ~strcmp(implementation,'optimized')
    error('BLASST:Implementation','Unknown implementation: %s',implementation);
end
% Both implementations follow the exact same interval loop.  The legacy
% numerical kernels in +blasstcore are untouched; only GUI events are new.
channelData = reshape(channelData,1,[]);
channelClean = channelData;
channelRemoved = zeros(size(channelData),'like',channelData);
counts = zeros(1,numel(frequencies));
countsBySegment = zeros(numel(frequencies),numel(starts));
for segmentIndex = activeSegments
    ticSegment = tic;
    sampleRange = starts(segmentIndex):ends(segmentIndex);
    raw = double(channelData(sampleRange));
    if ~all(raw == raw(1))
        if strcmp(implementation,'legacy')
            if isinf(segmentSamples) || numel(raw) <= segmentSamples
                [output,dropped,segmentCounts] = blasstcore.denoiseRecord( ...
                    raw,frequencies,widths,fs,scale,resolution,maxIterations);
            else
                [output,dropped,segmentCounts] = blasstcore.denoiseSegmented( ...
                    raw,frequencies,widths,fs,scale,resolution, ...
                    maxIterations,segmentSamples);
            end
        else
            if isinf(segmentSamples) || numel(raw) <= segmentSamples
                [output,dropped,segmentCounts] = blasstoptACH.denoiseRecord( ...
                    raw,frequencies,widths,fs,scale,resolution,maxIterations);
            else
                [output,dropped,segmentCounts] = blasstdispatch.denoiseSegmented( ...
                    raw,frequencies,widths,fs,scale,resolution, ...
                    maxIterations,segmentSamples);
            end
        end
        if any(~isfinite(output)) || any(~isfinite(dropped))
            error('BLASST:Numerical', ...
                'Nonfinite result for continuous interval %d.',segmentIndex);
        end
        channelClean(sampleRange) = cast(output,'like',channelData);
        channelRemoved(sampleRange) = cast(dropped,'like',channelData);
        counts = max(counts,reshape(segmentCounts,1,[]));
        countsBySegment(:,segmentIndex) = segmentCounts(:);
    end
    if ~isempty(segmentCallback)
        segmentCallback(segmentIndex,toc(ticSegment),numel(raw));
    end
end
end
