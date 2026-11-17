function [clean,removed,counts] = denoiseSegmented(raw, frequencies, widths, fs, scale, resolution, maxIterations, segmentSamples)
%DENOISESEGMENTED Optimized segment processing with unchanged context rule.
% This is an optional approximate-to-whole-record mode; never claim parity.
% This mode is not mathematically equivalent to whole-record BLASST.
% SPDX-License-Identifier: Apache-2.0
raw = double(reshape(raw,1,[]));
N = numel(raw);
clean = zeros(1,N);
removed = zeros(1,N);
counts = zeros(1,numel(frequencies));
context = max(4*scale,round(10*fs)); % robust extended context, not an exact global fit
for coreStart = 1:segmentSamples:N
    coreEnd = min(coreStart+segmentSamples-1,N);
    extStart = max(1,coreStart-context);
    extEnd = min(N,coreEnd+context);
    [localClean,~,localCounts] = blasstoptACH.denoiseRecord( ...
        raw(extStart:extEnd),frequencies,widths,fs,scale,resolution,maxIterations);
    localInd = (coreStart:coreEnd)-extStart+1;
    clean(coreStart:coreEnd) = localClean(localInd);
    counts = max(counts,localCounts);
end
removed = raw-clean;
end
