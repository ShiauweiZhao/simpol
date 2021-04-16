classdef PolarionURLParser
    % PolarionURLParser Extracts information from a polarion work item URL
    
    properties(SetAccess=private, GetAccess=public)
        url % PolarionURL
    end
    
    methods
        function obj = PolarionURLParser(url)
            obj.url = convertCharsToStrings(url);
        end
        
        % -----------------------------------------------------------------
        
        function id = getWorkItemId(obj)
            % Returns the work item ID as string. Returns  "" if the ID cannot be
            % parsed.
            
            u = obj.url;
            
            idx1 = strfind(u, "id=");
            
            if isempty(idx1) || ~contains(u, "workitem")
                id = "";
            else
                u = extractAfter(u, idx1+2);
                idx2 = strfind(u, "&");
                if isempty(idx2)
                    id = u;
                else
                    id = extractBefore(u, idx2);
                end
            end
        end
    end
end

