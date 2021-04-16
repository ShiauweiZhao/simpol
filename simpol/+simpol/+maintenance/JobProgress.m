classdef (ConstructOnLoad) JobProgress < event.EventData
    % JobProgress Wrapper for event data used for job progress
    
    properties
        message string = "";
        progress double = 0;
    end
    
    methods
        function data = JobProgress(progress, message)
            data.message = message;
            data.progress = progress;            
        end
    end
end