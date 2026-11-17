function nSmooth = nextSmooth7(nMinimum)
%NEXTSMOOTH7 Smallest integer >= nMinimum with factors only 2, 3, 5, 7.
% Test-only; persistent lookup avoids re-running the factor search in each
% Bhattacharyya test or atomic-iteration modulation convolution.
% SPDX-License-Identifier: Apache-2.0
validateattributes(nMinimum,{'numeric'},{'scalar','finite','positive','integer'});
persistent knownN knownSmooth
if isempty(knownN)
    knownN = zeros(1,0);
    knownSmooth = zeros(1,0);
end
idx = find(knownN == nMinimum,1);
if ~isempty(idx)
    nSmooth = knownSmooth(idx);
    return
end
nSmooth = double(nMinimum);
while true
    remainder = nSmooth;
    for prime = [2 3 5 7]
        while mod(remainder,prime)==0
            remainder = remainder/prime;
        end
    end
    if remainder==1
        break
    end
    nSmooth = nSmooth + 1;
end
knownN(end+1) = nMinimum;
knownSmooth(end+1) = nSmooth;
end
