function test_blasst_implementation_parallel()
%TEST_BLASST_IMPLEMENTATION_PARALLEL Validate both modes across scheduling.
if ~blasstcore.hasParallelToolbox()
    fprintf('SKIP: Parallel Computing Toolbox not available.\n');
    return
end
rng(20261117,'twister');
fs=250; N=10000; t=(0:N-1)/fs;
x=single([sin(2*pi*60*t)+0.05*randn(1,N); ...
    cos(2*pi*60*t)+0.10*randn(1,N); zeros(1,N)]);
opts={'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'MaxIterations',2, ...
    'BoundaryCuts',[3500 6500], 'ShowProgress',false};
for k=1:2
    if k==1, implementation='legacy'; else, implementation='optimized'; end
    [a,b,ra]=blasst_standalone(x,fs,opts{:}, ...
        'Implementation',implementation,'ExecutionMode','serial');
    [c,d,rb]=blasst_standalone(x,fs,opts{:}, ...
        'Implementation',implementation,'ExecutionMode','parallel');
    assert(isequal(ra.acceptedIterations,rb.acceptedIterations));
    assert(isequal(ra.acceptedIterationsByContinuousSegment, ...
        rb.acceptedIterationsByContinuousSegment));
    e1=norm(double(a(:))-double(c(:)))/max(norm(double(a(:))),eps);
    e2=norm(double(b(:))-double(d(:)))/max(norm(double(b(:))),eps);
    assert(e1<=1e-12 && e2<=1e-12);
end
fprintf('PASS serial/parallel agreement for both implementations.\n');
end
