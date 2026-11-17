classdef ProgressTracker < handle
    %PROGRESSTRACKER Client-side interval and channel progress with ETA.
    % The same display is used for legacy/optimized and serial/parallel.
    % BLASST numerical outputs never depend on this class.
    % SPDX-License-Identifier: Apache-2.0
    properties (SetAccess = private)
        Total
        Completed = 0
        WorkerCount
        DisplayEnabled
        Mode
        StartClock
        SecondsByCompletion
        RemainingMinutesByCompletion
        ChannelByCompletion
        TrialByCompletion
        ProgressWindow = []
        SegmentLengths = []
        TotalSegments = 0
        CompletedSegments = 0
        TotalSamples = 0
        CompletedSamples = 0
        SegmentElapsedSeconds = []
        ProgressFraction = 0
    end
    methods
        function obj = ProgressTracker(total,workers,showProgress,ticStart,mode,segmentLengths,implementation)
            if nargin < 6
                segmentLengths = [];
            end
            if nargin < 7
                implementation = '';
            end
            obj.Total = total;
            obj.WorkerCount = max(1,workers);
            obj.DisplayEnabled = logical(showProgress);
            obj.Mode = mode;
            obj.StartClock = ticStart;
            obj.SecondsByCompletion = nan(1,total);
            obj.RemainingMinutesByCompletion = nan(1,total);
            obj.ChannelByCompletion = nan(1,total);
            obj.TrialByCompletion = nan(1,total);
            obj.SegmentLengths = segmentLengths(:)';
            obj.TotalSegments = total*numel(obj.SegmentLengths);
            obj.TotalSamples = total*sum(obj.SegmentLengths);
            obj.SegmentElapsedSeconds = nan(1,obj.TotalSegments);
            if obj.DisplayEnabled && total > 0 && usejava('desktop')
                try
                    obj.ProgressWindow = waitbar(0, ...
                        'BLASST: starting; estimating remaining time...', ...
                        'Name',sprintf('BLASST progress (%s)',implementation));
                    set(obj.ProgressWindow,'Tag','BLASSTStandaloneProgress', ...
                        'Color',[0.66 0.76 1]);
                    % Use the same classic EEGLAB colors for progress text.
                    textControls = findall(obj.ProgressWindow, ...
                        'Type','uicontrol','Style','text');
                    if ~isempty(textControls)
                        set(textControls,'BackgroundColor',[0.66 0.76 1], ...
                            'ForegroundColor',[0 0 0.4]);
                    end
                    % Flush graphics BEFORE an uninterrupted EEG computation.
                    % Otherwise a short optimized run may finish before the
                    % desktop ever paints the waitbar window.
                    drawnow;
                catch
                    obj.ProgressWindow = [];
                end
            end
        end

        function record(obj,message)
            % This callback is invoked only on the MATLAB client.
            if isfield(message,'kind') && strcmp(message.kind,'segment')
                obj.recordSegment(message);
                return
            end
            if obj.Completed >= obj.Total
                return
            end
            k = obj.Completed + 1;
            obj.Completed = k;
            obj.SecondsByCompletion(k) = message.seconds;
            obj.ChannelByCompletion(k) = message.channel;
            obj.TrialByCompletion(k) = message.trial;
            remaining = obj.Total-k;
            estimateMin = median(obj.SecondsByCompletion(1:k)) * ...
                remaining / obj.WorkerCount / 60;
            obj.RemainingMinutesByCompletion(k) = estimateMin;
            if ~obj.DisplayEnabled
                return
            end
            fprintf(['BLASST %d/%d (%.1f s) ch %d, trial %d; ', ...
                'total %.1f s; accepted iterations %d; ', ...
                'estimated remaining %.1f min (%s, %d worker(s))\n'], ...
                k,obj.Total,message.seconds,message.channel,message.trial, ...
                toc(obj.StartClock),message.acceptedAtoms, ...
                estimateMin,obj.Mode,obj.WorkerCount);
            if obj.TotalSegments == 0
                fraction = k/max(1,obj.Total);
                label = sprintf('Channel %d/%d | Estimated remaining: %.1f min', ...
                    k,obj.Total,estimateMin);
            elseif k == obj.Total && obj.CompletedSegments == obj.TotalSegments
                fraction = 1;
                label = sprintf('Completed %d/%d channels',k,obj.Total);
            else
                % Keep interval-based progress, avoiding a backwards jump.
                fraction = obj.CompletedSamples/max(1,obj.TotalSamples);
                label = sprintf('%d/%d channels | %d/%d intervals completed', ...
                    k,obj.Total,obj.CompletedSegments,obj.TotalSegments);
            end
            obj.drawProgress(fraction,label);
        end

        function recordSegment(obj,message)
            if obj.CompletedSegments >= obj.TotalSegments
                return
            end
            k = obj.CompletedSegments+1;
            obj.CompletedSegments = k;
            obj.CompletedSamples = min(obj.TotalSamples, ...
                obj.CompletedSamples+message.samples);
            obj.SegmentElapsedSeconds(k) = message.seconds;
            if ~obj.DisplayEnabled
                return
            end
            fraction = obj.CompletedSamples/max(1,obj.TotalSamples);
            secondsPerSample = sum(obj.SegmentElapsedSeconds(1:k)) / ...
                max(1,obj.CompletedSamples);
            remainingSeconds = secondsPerSample * ...
                (obj.TotalSamples-obj.CompletedSamples) / obj.WorkerCount;
            if remainingSeconds < 60
                estimateText = sprintf('%.0f s',remainingSeconds);
            else
                estimateText = sprintf('%.1f min',remainingSeconds/60);
            end
            label = sprintf('Interval %d/%d | %.0f%% | Estimated remaining: %s', ...
                k,obj.TotalSegments,100*fraction,estimateText);
            obj.drawProgress(fraction,label);
        end

        function drawProgress(obj,fraction,label)
            % All graphics calls are made from the client, never a worker.
            obj.ProgressFraction = max(obj.ProgressFraction,min(1,fraction));
            if ~isempty(obj.ProgressWindow) && isgraphics(obj.ProgressWindow)
                try
                    waitbar(obj.ProgressFraction,obj.ProgressWindow,label);
                    drawnow limitrate
                catch
                    % Closing the popup must never cancel BLASST filtering.
                    obj.ProgressWindow = [];
                end
            end
        end

        function close(obj)
            if ~isempty(obj.ProgressWindow) && isgraphics(obj.ProgressWindow)
                delete(obj.ProgressWindow);
            end
            obj.ProgressWindow = [];
        end
    end
end
