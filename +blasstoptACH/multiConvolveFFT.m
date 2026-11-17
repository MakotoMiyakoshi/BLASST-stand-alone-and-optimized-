function C = multiConvolveFFT(filters,y)
%MULTICONVOLVEFFT EXPERIMENTAL 7-smooth zero-padding (test only).
% Preserves original full-linear-convolution crop; FFT roundoff may change.
% Adapted from Kenneth R. Ball's BLASST (2015), Apache-2.0.
% SPDX-License-Identifier: Apache-2.0
nn = blasstoptACH.nextSmooth7(size(filters,2)+length(y));
yF = fft(y,nn);
% The filter banks are invariant across channels and accepted iterations.
% Keep exact filter contents as the key so changing scientific parameters
% can never reuse an FFT from a different dictionary. The cache is local to
% each MATLAB process and bounded to 768 MiB.
persistent cache
if isempty(cache)
    cache = struct('length',{},'filters',{},'transform',{},'bytes',{});
end
match = 0;
for k = 1:numel(cache)
    if cache(k).length == nn && isequal(cache(k).filters,filters)
        match = k;
        break
    end
end
if match > 0
    fF = cache(match).transform;
else
    fF = fft(filters,nn,2);
    bytes = 16*numel(fF) + 16*numel(filters);
    maxBytes = 768*1024^2;
    if bytes <= maxBytes
        while ~isempty(cache) && sum([cache.bytes])+bytes > maxBytes
            cache(1) = [];
        end
        cache(end+1) = struct('length',nn,'filters',filters, ...
            'transform',fF,'bytes',bytes);
    end
end
C = ifft(bsxfun(@times,yF,fF),[],2);
C = C(:,floor(size(filters,2)/2+1)+(0:length(y)-1));
end
