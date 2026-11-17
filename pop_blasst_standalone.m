function [EEG, com, report] = pop_blasst_standalone(EEG, varargin)
%POP_BLASST_STANDALONE EEGLAB GUI + scriptable BLASST processing entry.
%   EEG = pop_blasst_standalone(EEG, 'LineFrequencies',60, ...
%       'HalfBandwidths',2, 'ScaleSeconds',4, 'MaxIterations',50);
%   Run with EEG only to open a MATLAB/EEGLAB-compatible settings dialog.
%   ExecutionMode: 'serial' or 'parallel' (requires Parallel Computing Toolbox).
%   Implementation: 'optimized' (default) or 'legacy' (PREP-derived adapted).
% SPDX-License-Identifier: Apache-2.0
com = '';
report = struct();
if nargin < 1 || isempty(EEG)
    help pop_blasst_standalone;
    return
end
if ~isstruct(EEG) || ~isfield(EEG,'data') || isempty(EEG.data) || ...
        ~isfield(EEG,'srate') || ~isfield(EEG,'nbchan')
    error('BLASST:EEGLAB', 'EEG must be a nonempty EEGLAB dataset struct.');
end
if ~isnumeric(EEG.data)
    error('BLASST:EEGLAB', 'Load continuous numeric EEG.data into memory first.');
end
if size(EEG.data,1) ~= EEG.nbchan
    error('BLASST:EEGLAB', 'EEG.nbchan does not match EEG.data.');
end

if isempty(varargin)
    % Always default to Serial, regardless of Parallel Computing Toolbox.
    % Parallel is available through explicit selection in the GUI or API.
    defaults = {'60','2','4','2','50','','Inf','serial','optimized'};
    answer = blasstdispatch.settingsDialog(defaults);
    if isempty(answer)
        return
    end
    freqs = blasstcore.parseNumbers(answer{1});
    widths = blasstcore.parseNumbers(answer{2});
    scale = blasstcore.parseNumbers(answer{3});
    resolution = blasstcore.parseNumbers(answer{4});
    iterations = blasstcore.parseNumbers(answer{5});
    channels = blasstcore.parseNumbers(answer{6});
    segsec = blasstcore.parseNumbers(answer{7});
    executionMode = answer{8};
    implementation = answer{9};
    if isempty(channels)
        channels = 1:EEG.nbchan;
    end
    varargin = {'LineFrequencies',freqs,'HalfBandwidths',widths, ...
        'ScaleSeconds',scale,'Resolution',resolution, ...
        'MaxIterations',iterations,'Channels',channels, ...
        'SegmentSeconds',segsec,'ExecutionMode',executionMode, ...
        'Implementation',implementation};
end

% The EEGLAB entry point shows channel-by-channel progress by default.
% Batch callers can supply 'ShowProgress',false to disable both outputs.
if mod(numel(varargin),2) == 0 && ...
        ~any(strcmpi(varargin(1:2:end),'ShowProgress'))
    varargin = [varargin, {'ShowProgress',true}];
end

% Respect EEGLAB discontinuity events; NEVER fit atoms across a boundary.
% For conventional K+0.5 boundary latencies, split after sample K.
% Edge boundaries and repeated boundaries create no empty intervals.
boundaryCuts = [];
boundaryEventCount = 0;
if (~isfield(EEG,'trials') || EEG.trials == 1) && ...
        isfield(EEG,'event') && ~isempty(EEG.event)
    [boundaryCuts,boundaryEventCount] = blasstcore.boundaryCuts( ...
        EEG.event, size(EEG.data,2));
end
[clean,~,report] = blasst_standalone(EEG.data,EEG.srate,varargin{:}, ...
    'BoundaryCuts',boundaryCuts, 'BoundaryEventCount',boundaryEventCount);

% Reproduce all user-facing choices in the EEGLAB history command.  The
% actual boundary cuts, normalized parameters, and source provenance are
% recorded separately in EEG.etc.BLASST, including a core replay argument
% list for use with the original (unprocessed) EEG data.
com = ['EEG = pop_blasst_standalone(EEG, ', ...
    '''LineFrequencies'',',mat2str(report.lineFrequencies),',', ...
    '''HalfBandwidths'',',mat2str(report.halfBandwidths),',', ...
    '''ScaleSeconds'',',num2str(report.scaleSecondsRequested,17),',', ...
    '''Resolution'',',num2str(report.resolution),',', ...
    '''MaxIterations'',',num2str(report.maxIterations),',', ...
    '''Channels'',',mat2str(report.channels),',', ...
    '''SegmentSeconds'',',num2str(report.segmentSeconds,17),',', ...
    '''ShowProgress'',',mat2str(report.showProgress),',', ...
    '''ExecutionMode'',''',report.executionModeRequested,''',', ...
    '''Implementation'',''',report.implementationUsed,''');'];

% Construct metadata BEFORE replacing EEG.data, so it describes the input
% dataset rather than a subsequent, already processed dataset.  No input
% samples are copied into the metadata.
metadata = blasstdispatch.buildMetadata(report,EEG,com);
EEG.data = clean;
if ~isfield(EEG,'etc') || isempty(EEG.etc)
    EEG.etc = struct();
end
EEG.etc.blasst_standalone = report; % Backward compatible with v0.3.1.
EEG.etc.BLASST = metadata;
if exist('eeg_checkset','file') == 2
    EEG = eeg_checkset(EEG);
end
end
