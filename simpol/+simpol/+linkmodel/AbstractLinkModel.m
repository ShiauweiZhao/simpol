classdef AbstractLinkModel
    % AbstractLinkModel Describes the necessary interfaces for a Polarion link model.
    % A concrete link model implements the algorithms to get, add, and remove
    % links between polarion work items and items in the Simulink domain.
    % The link model is stateless.
        
    methods(Static, Abstract)
        % getLinks Returns of links for a particular work item. 
        % jWorkItem Polarion work item object (java)
        % Returns an array of untyped link structs. For required field names,
        % refer to simpol.data.Link
        links = getLinks(h, polarionAdapter, item, jWorkItem);

        % addLinkToSimulink Depending on the link model, uses adapters to add a link
        % from  a Polarion work item to a Simulink item.
        % workItemId - ID of the Polarion work item.
        % Data - Required fields are "mItemId" and "url".
        % Returns true if the link could be added, false otherwise.
        b = addLinkToSimulink(h, polarionAdapter, rmiAdapter, workItemId, data);
        
        % removeLinkToSimulink Removes a link depending on the link model.
        % link Link of type simpol.data.Link
        % Returns true if the link could be removed.
        b = removeLinkToSimulink(h, polarionAdapter, rmiAdapter, link);
    end
    
end

