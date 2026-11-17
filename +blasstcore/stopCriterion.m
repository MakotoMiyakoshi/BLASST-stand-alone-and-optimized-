function [BDist,maxFlag,details] = stopCriterion(x,f,r,sR,scale)
%STOPCRITERION Bhattacharyya distance for BLASST stopping.
% Adapted from Kenneth R. Ball's blasst_test.m (2015), Apache-2.0.
% SPDX-License-Identifier: Apache-2.0
x = double(reshape(x,1,[]));
N = numel(x);
n2 = scale*2;
win = -n2:n2;
frequencyGrid = sR*(0:(1/(2*scale)):.5);
fs = frequencyGrid(frequencyGrid >= f-r & frequencyGrid <= f+r);
tfsl = frequencyGrid(frequencyGrid >= f-3*r & frequencyGrid <= f-2*r);
tfsr = frequencyGrid(frequencyGrid >= f+2*r & frequencyGrid <= f+3*r);
tfs = [tfsl,tfsr];
if isempty(fs) || isempty(tfs)
    error('BLASST:FrequencyGrid','No spectral atoms within target or reference bands.');
end
wavelets = blasstcore.complexGabor(fs/sR,scale,0,win);
testWavelets = blasstcore.complexGabor(tfs/sR,scale,0,win);
C = blasstcore.multiConvolveFFT(wavelets,x);
D = blasstcore.multiConvolveFFT(testWavelets,x);
testWeights = zeros(length(fs),length(tfs));
for kk = 1:length(fs)
    testWeights(kk,:) = fs(kk)-tfs;
end
testWeights = abs(1./testWeights);
testWeights = bsxfun(@times,testWeights,1./sum(testWeights,2));
D = abs(D);
C = abs(C);
binCount = ceil(2*N^(1/3));
[DHists,centers] = hist(log((abs(D).^2)'),binCount);
DHists = DHists/N;
DCompare = mean(DHists*testWeights',2);
CHists = hist(log((abs(C).^2)'),centers);
CHists = CHists/N;
CCompare = mean(CHists,2);
[~,CMaxInd] = max(CCompare);
maxFlag = CMaxInd == binCount;
BDist = -log(sum(sqrt(DCompare.*CCompare))+1e-8);
details = struct('CHist',CHists,'DHist',DHists,'CCompare',CCompare,...
    'DCompare',DCompare,'centers',centers);
end
