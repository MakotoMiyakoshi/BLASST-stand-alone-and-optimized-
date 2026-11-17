classdef ProgressTracker < handle
    %PROGRESSTRACKER Client-side channel progress and robust median ETA.
    % Numeric BLASST fitting does not depend on this class or its state.
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
    end
    methods
        function obj = ProgressTracker(total,workers,showProgress,ticStart,mode)
            obj.Total = total;
            obj.WorkerCount = max(1,workers);
            obj.DisplayEnabled = logical(showProgress);
            obj.Mode = mode;
            obj.StartClock = ticStart;
            obj.SecondsByCompletion = nan(1,total);
            obj.RemainingMinutesByCompletion = nan(1,total);
            obj.ChannelByCompletion = nan(1,total);
            obj.TrialByCompletion = nan(1,total);
            if obj.DisplayEnabled && total > 0 && usejava('desktop')
                try
                    obj.ProgressWindow = waitbar(0, ...
                        'BLASST: estimating remaining time...', ...
                        'Name','BLASST channel progress');
                catch
                    obj.ProgressWindow = [];
                end
            end
        end

        function record(obj,message)
            % Called only from the client: directly in serial mode, or
            % via parallel.pool.DataQueue.afterEach in parallel mode.
            if obj.Completed >= obj.Total
                return
            end
            k = obj.Completed + 1;
            obj.Completed = k;
            obj.SecondsByCompletion(k) = message.seconds;
            obj.ChannelByCompletion(k) = message.channel;
            obj.TrialByCompletion(k) = message.trial;
            remaining = obj.Total - k;
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
            if ~isempty(obj.ProgressWindow) && isgraphics(obj.ProgressWindow)
                try
                    waitbar(k/obj.Total,obj.ProgressWindow, ...
                        sprintf('%d/%d | Estimated remaining: %.1f min', ...
                        k,obj.Total,estimateMin));
                    drawnow limitrate
                catch
                    % Closing the progress window never aborts analysis.
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
