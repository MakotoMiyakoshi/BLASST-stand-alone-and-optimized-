function [y,x] = atomicIteration(x,f,r,sR,scale,rez,manualOffset)
%ATOMICITERATION One matching-pursuit pass using Gabor atoms.
% Adapted from Kenneth R. Ball's blasst_internal.m (2015), Apache-2.0.
% SPDX-License-Identifier: Apache-2.0
x = double(reshape(x,1,[]));
N = length(x);
y = zeros(size(x));
n2 = scale*2;
n = 2*n2+1;
win = -n2:n2;
timeJump = scale/rez/sqrt(pi);
R = -(rez*10):(rez*10);
scalingFactor = 1./sum(exp(-R.^2/rez.^2));

frequencyGrid = sR*(0:(1/(2*scale)):.5);
fs = frequencyGrid(frequencyGrid >= f-r & frequencyGrid <= f+r);
tfsl = frequencyGrid(frequencyGrid >= f-3*r & frequencyGrid <= f-2*r);
tfsr = frequencyGrid(frequencyGrid >= f+2*r & frequencyGrid <= f+3*r);
tfs = [tfsl,tfsr];
if isempty(fs) || isempty(tfs)
    error('BLASST:FrequencyGrid', 'No Gabor frequencies in target or reference band.');
end
wavelets = blasstoptACH.complexGabor(fs/sR,scale,0,win);
testWavelets = blasstoptACH.complexGabor(tfs/sR,scale,0,win);
modulator = blasstoptACH.buildPowerModulator([zeros(1,2*n),x,zeros(1,2*n)], ...
    testWavelets,fs,tfs);

centers = (1+manualOffset):timeJump:N;
if numel(centers) < 3
    error('BLASST:ShortRecording', 'Too few atom centers; increase recording length.');
end
leftCenters = centers(1);
centers = centers(2:end);
while round(leftCenters(1)) > -n2+1
    leftCenters = cat(2,leftCenters(1)-timeJump,leftCenters);
end
while round(leftCenters(end)) < n2
    leftCenters = cat(2,leftCenters,leftCenters(end)+timeJump);
    centers = centers(2:end);
end
rightCenters = centers(end);
centers = centers(1:end-1);
while round(rightCenters(end)) < N+n2
    rightCenters = cat(2,rightCenters,rightCenters(end)+timeJump);
end
while round(rightCenters(1)) > N-n2
    rightCenters = cat(2,rightCenters(1)-timeJump,rightCenters);
    centers = centers(1:end-1);
end
centers = round([leftCenters,centers,rightCenters]);
weights = (erf(sqrt(pi)*(N-centers)/scale)-erf(sqrt(pi)*(1-centers)/scale))/2;
weights = weights(2:end-1);
centers = centers(2:end-1);

x = [zeros(1,2*n),x,zeros(1,2*n)];
y = [zeros(1,2*n),y,zeros(1,2*n)];
X = zeros(length(centers),n);
pM = zeros(size(X,1),size(modulator,1));
centers = centers+2*n;
for jj = 1:length(centers)
    X(jj,:) = x((-n2:n2)+centers(jj));
    pM(jj,:) = mean(modulator(:,round(((-scale/(2*rez)):(scale/(2*rez))) + centers(jj))),2)';
end
innerProducts = X*wavelets.';
phase = -angle(innerProducts);
amplitude = max(0,abs(innerProducts)-pM);
[amps,whichFreq] = max(amplitude,[],2);
realWavelets = zeros(size(X,1),n);
for jj = 1:size(X,1)
    realWavelets(jj,:) = real(exp(1i*phase(jj,whichFreq(jj))) * ...
        wavelets(whichFreq(jj),:));
end
realWavelets = bsxfun(@times,scalingFactor*amps./weights',realWavelets)*sqrt(2);
for jj = 1:length(centers)
    x((-n2:n2)+centers(jj)) = x((-n2:n2)+centers(jj))-realWavelets(jj,:);
    y((-n2:n2)+centers(jj)) = y((-n2:n2)+centers(jj))+realWavelets(jj,:);
end
x = x((2*n+1):(end-2*n));
y = y((2*n+1):(end-2*n));
end
