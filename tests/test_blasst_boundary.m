function test_blasst_boundary()
%TEST_BLASST_BOUNDARY Boundary-aware independent fitting and unchanged spans.
% Standalone (EEGLAB-independent) deterministic test.
% SPDX-License-Identifier: Apache-2.0
rng(20261117,'twister');
fs = 250;
N = 12500;
t = (0:N-1)/fs;
data = single([sin(2*pi*60*t)+0.2*randn(1,N);randn(1,N)]);
opts = {'LineFrequencies',60,'HalfBandwidths',2, ...
    'ScaleSeconds',0.5,'Resolution',2,'MaxIterations',1,'Channels',1};
cuts = [250 4100 8800];
[clean,removed,report] = blasst_standalone(data,fs,opts{:},'BoundaryCuts',cuts);
assert(isequal(size(clean),size(data)) && isa(clean,'single'));
assert(isequal(clean(2,:),data(2,:)));
assert(isequal(clean(:,1:250),data(:,1:250))); % Short span unchanged.
assert(all(removed(:,1:250) == 0,'all'));
assert(isequal(report.boundaryCuts,cuts));
assert(report.boundaryMode && report.boundaryEventCount == 0);
assert(isequal(report.continuousSegmentRanges,[1 250;251 4100;4101 8800;8801 N]));
assert(isequal(report.skippedSegmentRanges,[1 250]));
assert(report.minimumSamplesRequired == 2500);
assert(report.processedSegmentCount == 3 && report.skippedSegmentCount == 1);
assert(report.skippedSampleCount == 250 && report.skippedSampleFraction == 250/N);
assert(max(abs(double(data(:))-double(clean(:))-double(removed(:)))) < 2e-5);
assert(isequal(size(report.acceptedIterationsByContinuousSegment),[2 1 4]));
for segmentIndex = 2:4
    sampleRange = report.continuousSegmentRanges(segmentIndex,1): ...
        report.continuousSegmentRanges(segmentIndex,2);
    [reference,~,referenceReport] = blasst_standalone(data(:,sampleRange),fs,opts{:});
    assert(isequal(clean(:,sampleRange),reference));
    assert(isequal(report.acceptedIterationsByContinuousSegment(:,:,segmentIndex), ...
        referenceReport.acceptedIterations));
end
% Read EEGLAB events exactly, including edge and duplicate boundaries.
events = struct('type',{'boundary','boundary','stim','boundary', ...
    'boundary','boundary','boundary'}, ...
    'latency',{0.5,250.5,2000,4100.5,4100.5,8800.5,N+0.5});
[eventCuts,eventCount] = blasstcore.boundaryCuts(events,N);
assert(isequal(eventCuts,cuts) && eventCount == 6);
% Edge-only boundary markers must not create empty data spans.
edgeEvents = struct('type',{'boundary','boundary'}, ...
    'latency',{0.5,2000.5});
[edgeCuts,edgeCount] = blasstcore.boundaryCuts(edgeEvents,2000);
assert(isempty(edgeCuts) && edgeCount == 2);
[edgeClean,edgeRemoved,edgeReport] = blasst_standalone(data(:,1:2000),fs, ...
    opts{:},'BoundaryCuts',edgeCuts,'BoundaryEventCount',edgeCount);
assert(isequal(edgeClean,data(:,1:2000)) && ~any(edgeRemoved(:)));
assert(edgeReport.skippedSampleFraction == 1 && edgeReport.boundaryMode);
% Even an all-short, boundary-separated record is a documented no-op.
shortData = data(:,1:2000);
[shortClean,shortRemoved,shortReport] = blasst_standalone(shortData,fs,opts{:}, ...
    'BoundaryCuts',[500 1100]);
assert(isequal(shortClean,shortData) && ~any(shortRemoved(:)));
assert(shortReport.processedSegmentCount == 0);
assert(shortReport.skippedSegmentCount == 3 && shortReport.skippedSampleFraction == 1);
% No cut: previous full-record behavior is preserved.
[fullClean,~,fullReport] = blasst_standalone(data,fs,opts{:});
[noCutClean,~,noCutReport] = blasst_standalone(data,fs,opts{:},'BoundaryCuts',[]);
assert(isequal(fullClean,noCutClean) && ...
    isequal(fullReport.acceptedIterations,noCutReport.acceptedIterations));
% Boundary cut index validation: reject off-grid and out-of-range cuts.
invalids = {0,N,3.5,NaN};
for k = 1:numel(invalids)
    failed = false;
    try
        blasst_standalone(data,fs,opts{:},'BoundaryCuts',invalids{k});
    catch ME
        failed = strcmp(ME.identifier,'BLASST:BoundaryCuts') || ...
            strcmp(ME.identifier,'MATLAB:InputParser:ArgumentFailedValidation');
    end
    assert(failed);
end
fprintf('PASS test_blasst_boundary (segment equivalence and skip coverage)\n');
end
