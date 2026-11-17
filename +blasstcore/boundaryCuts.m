function [cuts, boundaryEventCount] = boundaryCuts(events, numberOfSamples)
%BOUNDARYCUTS Convert EEGLAB boundary latencies into contiguous sample cuts.
%   A boundary at latency K+0.5 lies between samples K and K+1.
%   Latencies 0.5 and N+0.5 are outside the data and produce no cut.
%   Any interior latency is assigned to the immediately preceding sample.
% SPDX-License-Identifier: Apache-2.0
cuts = zeros(1,0);
boundaryEventCount = 0;
if isempty(events)
    return
end
if ~(isstruct(events) && isfield(events,'type'))
    error('BLASST:Boundary', 'EEGLAB events must be structs with a type field.');
end
for eventIndex = 1:numel(events)
    eventType = events(eventIndex).type;
    if isstring(eventType) && isscalar(eventType)
        eventType = char(eventType);
    end
    if ~(ischar(eventType) && strcmpi(eventType,'boundary'))
        continue
    end
    boundaryEventCount = boundaryEventCount + 1;
    if ~isfield(events,'latency')
        error('BLASST:Boundary', 'Boundary event %d has no latency.', eventIndex);
    end
    latency = events(eventIndex).latency;
    if ~(isnumeric(latency) && isreal(latency) && isscalar(latency) && ...
            isfinite(latency) && latency >= 0.5 && ...
            latency <= numberOfSamples + 0.5)
        error('BLASST:Boundary', ...
            'Boundary event %d has an invalid/out-of-range latency.', eventIndex);
    end
    cut = floor(double(latency));
    if cut >= 1 && cut < numberOfSamples
        cuts(end+1) = cut; %#ok<AGROW>
    end
end
cuts = unique(cuts);
end
