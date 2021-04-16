classdef AutoSuspicionModel < simpol.suspicion.AbstractSuspicionModel
    % AutoSupsicionModel Reads the suspicion from the polarion item and
    % propagates it to the links
    
    methods(Static)
        function [polarionIsSuspected, matlabIsSuspected] = ...
            areLinksSuspected(polarionAdapter, polarionLinkProps, ...
                                 ~, matlabLinkProps)
            
            polarionIsSuspected = false(size(polarionLinkProps, 1), 1);
            matlabIsSuspected = false(size(matlabLinkProps, 1), 1);
        
            for i = 1:size(polarionLinkProps, 1)
                
                link = polarionLinkProps.Link(i);
                item_p = polarionAdapter.getCachedItem(link.itemId);
                
                if ~isempty(item_p)
                    polarionIsSuspected(i) = item_p.suspected;
                    
                    % If the link is bi-directional, also the counter link
                    % becomes suspected
                    if item_p.suspected
                        j = polarionLinkProps.CounterIndex(i);
                        if  j > 0
                            matlabIsSuspected(j) = true;
                        end
                    end
                end
            end
            
        end
        
        % -----------------------------------------------------------------
        
        function b = allowsUnsuspect()
            b = false;
        end
        
    end
end

