classdef RevisionSuspicionModel < simpol.suspicion.AbstractSuspicionModel

    methods(Static)
        function [polarionIsSuspected, matlabIsSuspected] = ...
            areLinksSuspected(polarionAdapter, polarionLinkProps, ...
                                 ~, matlabLinkProps)
                             
            polarionIsSuspected = false(size(polarionLinkProps, 1), 1);
            matlabIsSuspected = false(size(matlabLinkProps, 1), 1);                             

            for i = 1:size(matlabLinkProps, 1)
                
                link_m = matlabLinkProps.Link(i);
                counterIndex = matlabLinkProps.CounterIndex(i);
                
                if counterIndex > 0
                    
                    link_p = polarionLinkProps.Link(counterIndex);                                        
                    item_p = polarionAdapter.getCachedItem(link_p.itemId);

                    if ~isempty(item_p)
                        matlabIsSuspected(i) = ~strcmp(...
                            item_p.lastUpdated,...
                            link_m.toRevision);
                        if matlabIsSuspected(i)
                            polarionIsSuspected(counterIndex) = true;
                        end
                    end
                end
            end
        end
        
        % -----------------------------------------------------------------
        
        function b = allowsUnsuspect()
            b = true;
        end        
    end
    
end

