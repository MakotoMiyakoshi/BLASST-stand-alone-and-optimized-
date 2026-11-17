function [x, removed, counts] = denoiseRecord(x, frequencies, widths, fs, scale, resolution, maxIterations)
%DENOISERECORD Original BLASST sequence and stopping criterion, per record.
% SPDX-License-Identifier: Apache-2.0
x = double(reshape(x,1,[]));
removed = zeros(size(x));
counts = zeros(1,numel(frequencies));
manualOffset = log2(scale)+1;
for k = 1:numel(frequencies)
    f = frequencies(k);
    r = widths(k);
    [prevDistance,~,~] = blasstcore.stopCriterion(x,f,r,fs,scale);
    for iteration = 1:maxIterations
        [candidateRemoved,candidate] = blasstcore.atomicIteration( ...
            x,f,r,fs,scale,resolution,(iteration-1)*manualOffset);
        [nextDistance,maxFlag,~] = blasstcore.stopCriterion(candidate,f,r,fs,scale);
        if nextDistance >= prevDistance && ~maxFlag
            break  % Never accept the pass that first worsens the criterion.
        end
        prevDistance = nextDistance;
        removed = removed+candidateRemoved;
        x = candidate;
        counts(k) = iteration;
    end
end
end
