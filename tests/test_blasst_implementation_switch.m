function test_blasst_implementation_switch()
%TEST_BLASST_IMPLEMENTATION_SWITCH Exact legacy preservation and ACH routing.
% Run with the staging plugin directory on the MATLAB path.
rng(271117,'twister');
fs = 250;
N = 10500;
t = (0:N-1)/fs;
x = single([sin(2*pi*60*t)+0.07*randn(1,N); ...
    0.5*cos(2*pi*60*t)+0.11*randn(1,N); zeros(1,N)]);
opts = {'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'Resolution',2,'MaxIterations',2, ...
    'Channels',[1 2],'BoundaryCuts',[3600 7200], ...
    'ShowProgress',false,'ExecutionMode','serial'};
[legacy,removedLegacy,rLegacy] = blasst_standalone(x,fs,opts{:}, ...
    'Implementation','legacy');
[optimized,removedOptimized,rOpt] = blasst_standalone(x,fs,opts{:}, ...
    'Implementation','optimized');
[defaultOut,defaultRemoved,rDefault] = blasst_standalone(x,fs,opts{:});
assert(strcmp(rLegacy.implementationUsed,'legacy'));
assert(strcmp(rOpt.implementationUsed,'optimized'));
assert(strcmp(rDefault.implementationUsed,'optimized'));
assert(isequal(optimized,defaultOut));
assert(isequal(removedOptimized,defaultRemoved));
assert(isequal(rOpt.acceptedIterations,rDefault.acceptedIterations));
assert(isequal(legacy(3,:),x(3,:)) && isequal(optimized(3,:),x(3,:)));
assert(isequal(rLegacy.boundaryCuts,[3600 7200]));
assert(isequal(rLegacy.acceptedIterations,rOpt.acceptedIterations));
errClean = norm(double(legacy(:))-double(optimized(:))) / ...
    max(norm(double(legacy(:))),eps);
errRemoved = norm(double(removedLegacy(:))-double(removedOptimized(:))) / ...
    max(norm(double(removedLegacy(:))),eps);
assert(errClean<=1e-12 && errRemoved<=1e-12);
% A direct invocation of the untouched legacy channel wrapper must match.
[directClean,directRemoved,directCounts,directBySegment] = ...
    blasstcore.denoiseChannel(x(1,:),[1 3601 7201],[3600 7200 N], ...
    1:3,60,2,fs,round(0.5*fs),2,2,Inf);
assert(isequal(legacy(1,:),directClean));
assert(isequal(removedLegacy(1,:),directRemoved));
assert(isequal(squeeze(rLegacy.acceptedIterations(1,:,1)),directCounts(:)));
assert(isequal(reshape(rLegacy.acceptedIterationsByContinuousSegment(1,:,:,1),[],1),directBySegment(:)));
fprintf('PASS dual core switch: legacy untouched; optimized default; numerical agreement.\n');
end
