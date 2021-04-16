classdef UpdateImages < simpol.maintenance.AbstractJob
    % UpdateImages Job that fixes old images
    
    
    methods(Static)
        function name = getName()
            name = 'Update Images';
        end
        
        function s = getDescription()
            s = "Updates all embedded images if changed. If surrogate linking " +...
                "is used, surrogate work item images get updated. Otherwise the " + ...
                "images directly embedded in the linked work item.";
        end
        
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods
        
        function executeImpl(h)
            
            progressOffset = .2;
            progressFraction = 1 - progressOffset;
            
            mgr = SimPol('instance');
            
            links = mgr.linkTable.queryLinks(simpol.SideType.POLARION,...
                "", "resolvable AND bidirectional");
            numLinks = numel(links);
            
            for iLink = 1:numLinks
                
                h.notify('JobProgressEvent',...
                 simpol.maintenance.JobProgress(...
                    iLink/numLinks * progressFraction + progressOffset,...
                    "Updating image " +  iLink + " of " + numLinks));                  
               
                
                mgr.addLink(links(iLink).itemId, links(iLink).toItemId);
            end
            
        end
    end
        
end

