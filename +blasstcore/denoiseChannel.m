function [channelClean,channelRemoved,counts,countsBySegment] = denoiseChannel( ...
    channelData,starts,ends,activeSegments,frequencies,widths,fs,scale, ...
    resolution,maxIterations,segmentSamples)
%DENOISECHANNEL Process boundary-separated segments of exactly one channel.
% One computational path for serial and parallel scheduling. Untouched
% intervals and the original sample order are preserved without interpolation.
% SPDX-License-Identifier: Apache-2.0
channelData = reshape(channelData,1,[]);
channelClean = channelData;
channelRemoved = zeros(size(channelData),'like',channelData);
counts = zeros(1,numel(frequencies));
countsBySegment = zeros(numel(frequencies),numel(starts));
for segmentIndex = activeSegments
    sampleRange = starts(segmentIndex):ends(segmentIndex);
    raw = double(channelData(sampleRange));
    if all(raw == raw(1))
        continue
    end
    if isinf(segmentSamples) || numel(raw) <= segmentSamples
        [output,dropped,segmentCounts] = blasstcore.denoiseRecord( ...
            raw,frequencies,widths,fs,scale,resolution,maxIterations);
    else
        [output,dropped,segmentCounts] = blasstcore.denoiseSegmented( ...
            raw,frequencies,widths,fs,scale,resolution,maxIterations,segmentSamples);
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
end
