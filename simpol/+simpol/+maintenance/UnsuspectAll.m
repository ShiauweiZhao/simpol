classdef UnsuspectAll < simpol.maintenance.AbstractJob
    % UnsuspectAll Unsuspects all links (if possible). This mainly means
    % recreating the links.
    
    methods(Static)
        function name = getName()
            name = "Unsuspect all";
        end
        
        % -----------------------------------------------------------------
        
        function s = getDescription()
            s = "Unuspects all suspected RMI work items by updating the uptrace checksum." + ...
                "Therefore, the links must be applicable and resolvable.";
        end
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods
        
        function executeImpl(h)
            
            mgr = SimPol('instance');
                        
            links = mgr.linkTable.queryLinks("", "resolvable AND bidirectional AND suspected");
            numLinks = numel(links);
            
            progressFraction = 1;
            progressOffset = 0;
            
            for iLink = 1:numLinks
                link = links(iLink);
                
                h.notify('JobProgressEvent',...
                    simpol.maintenance.JobProgress(...
                        iLink/numLinks * progressFraction + progressOffset,...
                        "Unsuspecting link " +  iLink + " of " + numLinks));  
                
                mgr.unsuspectLink(simpol.SideType.MATLAB,...
                    link.id);
            end
            
        end
    end
    
    
end

