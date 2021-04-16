classdef AbstractJob < handle
    % AbstractJob Interface for patch jobs
            
    events
        JobProgressEvent;
    end

    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------    
    
    methods(Abstract)
        % Overwrite to execute the job.
        executeImpl(h);        
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods(Abstract, Static)
        % Returns a human-readable name of the job
        name = getName();
        
        % Returns a description of the job 
        s = getDescription();
    end 
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods
        function execute(h)
            mgr = SimPol('instance');
            
            h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(0, "Updating caches...")); 
            
            mgr.matlabAdapter.updateCache();
            mgr.polarionAdapter.updateCache();
            mgr.updateLinkTable();
            
            h.executeImpl();
            
            h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(1, "Done.")); 
            
        end
    end
end

