function test_blasst_eta_parallel()
%TEST_BLASST_ETA_PARALLEL Unit test for client-side asynchronous ETA math.
% Independent of worker pool availability and the BLASST numerical kernels.
% SPDX-License-Identifier: Apache-2.0
t0 = tic;
tracker = blasstcore.ProgressTracker(10,4,false,t0,'parallel');
tracker.record(struct('channel',7,'trial',1,'seconds',4, 'acceptedAtoms',2));
assert(tracker.Completed == 1);
assert(abs(tracker.RemainingMinutesByCompletion(1) - (4*9/4/60)) < 1e-12);
tracker.record(struct('channel',2,'trial',1,'seconds',6, 'acceptedAtoms',1));
assert(abs(tracker.RemainingMinutesByCompletion(2) - (5*8/4/60)) < 1e-12);
tracker.record(struct('channel',9,'trial',1,'seconds',5, 'acceptedAtoms',3));
assert(isequal(tracker.ChannelByCompletion(1:3),[7 2 9]));
assert(abs(tracker.RemainingMinutesByCompletion(3) - (5*7/4/60)) < 1e-12);
tracker.close();
fprintf('PASS test_blasst_eta_parallel (median duration / worker count)\n');
end
