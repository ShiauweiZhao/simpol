classdef Item < handle
    %Item Data model element representing items either on Polarion or
    %MATLAB side.
    
    properties
        id string = "";
        name string = "";
        description string = "";
        lastUpdated string = "";
        parentWorkItemIds string;
        optional;   
        suspected = false; % Suspected state of the item, not the link 
        links simpol.data.Link;
    end
    
    methods
        function h = Item()
            h.optional = containers.Map;
        end
    end
   
end

