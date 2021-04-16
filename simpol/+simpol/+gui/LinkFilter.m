classdef LinkFilter
    % Wrapper for filtering links for a particular item
    
    properties
        queryString string = "";
    end
    
    % ---------------------------------------------------------------------
    
    methods
        function obj = LinkFilter(queryString)
            if nargin == 1
                obj.queryString = convertCharsToStrings(queryString);
            end
        end
        
        % -----------------------------------------------------------------
        
        function [links, linkProperties] = exec(h, side, itemId, linkTable)
            [links, linkProperties] = linkTable.queryLinks(...
                side, string(itemId), h.queryString);            
        end
    end
end

