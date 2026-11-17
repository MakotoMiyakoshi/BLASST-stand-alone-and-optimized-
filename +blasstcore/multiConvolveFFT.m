function C = multiConvolveFFT(filters,y)
%MULTICONVOLVEFFT Match BLASST FFT convolution alignment.
% Adapted from Kenneth R. Ball's BLASST (2015), Apache-2.0.
% SPDX-License-Identifier: Apache-2.0
nn = size(filters,2)+length(y);
yF = fft(y,nn);
fF = fft(filters,nn,2);
C = ifft(bsxfun(@times,yF,fF),[],2);
C = C(:,floor(size(filters,2)/2+1)+(0:length(y)-1));
end
