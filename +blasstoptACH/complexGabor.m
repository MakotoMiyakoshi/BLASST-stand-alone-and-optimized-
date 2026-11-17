function gaborFun = complexGabor(f,s,u,time)
%COMPLEXGABOR Complex Gabor dictionary, source-equivalent normalization.
% Adapted from Kenneth R. Ball's BLASST (2015), Apache-2.0.
% SPDX-License-Identifier: Apache-2.0
s = s';
f = f';
if ~isinf(s)
    g1 = bsxfun(@times,2^(1/4)/sqrt(s),exp(-pi/s^2*(time-u).^2));
    gaborFun = bsxfun(@times,g1,exp(1i*2*pi*f*(time-u)));
else
    gaborFun = exp(1i*2*pi*f*(time-u));
end
end
