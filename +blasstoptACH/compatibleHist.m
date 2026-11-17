function [counts,centers] = compatibleHist(y,spec)
%COMPATIBLEHIST Numerical matrix histogram with hist-compatible bin edges.
% This mirrors the scalar-bin and supplied-center branches of R2024b hist
% used by BLASST, including its one-ULP edge shift. Each column is binned
% independently by histcounts. No graphics or categorical paths are used.
% Modified implementation (C) 2026, BLASST Standalone contributors.
% SPDX-License-Identifier: Apache-2.0
assert(isnumeric(y) && isreal(y) && ~isempty(y));
if isscalar(spec)
    binCount = spec;
    miny = min(y(:)); maxy = max(y(:));
    if ~isfinite(miny) || ~isfinite(maxy)
        finiteY = y(isfinite(y));
        if isempty(finiteY)
            miny = 0; maxy = 0;
        else
            miny = min(finiteY); maxy = max(finiteY);
        end
    end
    if miny == maxy
        miny = miny - floor(binCount/2) - 0.5;
        maxy = maxy + ceil(binCount/2) - 0.5;
    end
    edges = linspace(miny,maxy,binCount+1);
    binwidth = edges(2)-edges(1);
    centers = edges(1:end-1)+binwidth/2;
    edges(1) = -Inf; edges(end) = Inf;
else
    centers = spec(:)';
    edges = [-Inf,centers(1:end-1)+diff(centers)/2,Inf];
    binCount = numel(centers);
end
edges = full(real(edges));
edges = edges+eps(edges);
edges(1) = -Inf; edges(end) = Inf;
y = full(real(y));
counts = zeros(binCount,size(y,2));
for j=1:size(y,2)
    counts(:,j) = histcounts(y(:,j),edges)';
end
centers = centers(:);
end
