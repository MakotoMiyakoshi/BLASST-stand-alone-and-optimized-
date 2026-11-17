function test_blasst_progress_tracker_intervals()
%TEST_BLASST_PROGRESS_TRACKER_INTERVALS Client-only progress accounting.
% SPDX-License-Identifier: Apache-2.0
t0 = tic;
p = blasstdispatch.ProgressTracker(2,2,false,t0,'parallel',[3000 1000],'optimized');
assert(p.TotalSegments == 4);
assert(p.TotalSamples == 8000);
p.record(struct('kind','segment','channel',1,'trial',1, ...
    'segment',1,'samples',3000,'seconds',3));
assert(p.CompletedSegments == 1);
assert(p.CompletedSamples == 3000);
p.record(struct('kind','segment','channel',2,'trial',1, ...
    'segment',1,'samples',3000,'seconds',2));
assert(p.CompletedSegments == 2);
p.record(struct('channel',1,'trial',1,'seconds',4,'acceptedAtoms',2));
assert(p.Completed == 1);
assert(p.CompletedSamples == 6000);
p.record(struct('kind','segment','channel',1,'trial',1, ...
    'segment',2,'samples',1000,'seconds',1));
p.record(struct('kind','segment','channel',2,'trial',1, ...
    'segment',2,'samples',1000,'seconds',1));
p.record(struct('channel',2,'trial',1,'seconds',3,'acceptedAtoms',1));
assert(p.Completed == 2);
assert(p.CompletedSegments == 4);
assert(p.CompletedSamples == p.TotalSamples);
assert(p.RemainingMinutesByCompletion(end) == 0);
p.close();
fprintf('PASS client segment progress and channel ETA accounting\n');
end
