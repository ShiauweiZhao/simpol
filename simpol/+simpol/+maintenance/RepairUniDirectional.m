classdef RepairUniDirectional < simpol.maintenance.AbstractJob
    % RecreateUniDirection Tries to convert uni-directional into
    % bi-direction relationships
    
    methods(Static)
        
        function name = getName()
            name = 'Recreate Uni-Directional';
        end
        
        % -----------------------------------------------------------------
        
        function s = getDescription()
            s = "This function re-establishes uni-directional links from both sides." + newline + ...
                "Therefore, uni-directional links must be resolvable.";
        end
        
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods
        
        function executeImpl(h)
            
            mgr = SimPol('instance');
                        
            h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(0.2, "Performing job on Polarion links...")); 
            
            h.recreate(0.2, mgr.polarionAdapter);
            
            h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(0.6, "Performing job on MATLAB links..."));
            
            h.recreate(0.6, mgr.matlabAdapter);
                       
        end
    end
    
    methods(Access=private)
        
        function recreate(h, progressOffset, adapter)
            
            progressFraction = 0.4;
            
            mgr = SimPol('instance');

            links = mgr.linkTable.queryLinks(...
                adapter.getSide(),...
                "",... % all items
                "resolvable AND ~bidirectional");
            
            numLinks = numel(links);
            
            for iLink = 1:numLinks
                
                h.notify('JobProgressEvent',...
                    simpol.maintenance.JobProgress(...
                        iLink/numLinks * progressFraction + progressOffset,...
                        "Fixing link " +  iLink + " of " + numLinks));                 
                
                link = links(iLink);
                
                if adapter.getSide() == simpol.SideType.MATLAB
                    mgr.addLink(link.toItemId, link.itemId);
                else
                    mgr.addLink(link.itemId, link.toItemId);
                end
                

            end
        end
        
    end
    
end

