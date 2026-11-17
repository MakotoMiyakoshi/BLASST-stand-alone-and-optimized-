function modulator = buildPowerModulator(x,testDict,targetFreqs,testFreqs)
%BUILDPOWERMODULATOR Geometric-neighbor-frequency BLASST modulation.
% Adapted from Kenneth R. Ball's BLASST (2015), Apache-2.0.
% SPDX-License-Identifier: Apache-2.0
C = blasstoptACH.multiConvolveFFT(testDict,x);
CmodWeights = zeros(length(targetFreqs),length(testFreqs));
for kk = 1:length(targetFreqs)
    CmodWeights(kk,:) = targetFreqs(kk)-testFreqs;
end
CmodWeights = abs(1./CmodWeights);
CmodWeights = bsxfun(@times,CmodWeights,1./sum(CmodWeights,2));
modulator = sqrt(exp(CmodWeights*log(abs(C).^2)));
end
