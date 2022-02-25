function addLink(h, workItemId, itemId_m)

    h.ensureIsWritable();
    h.polarionAdapter.ensureOpenSession;

    % Check if mItemId exists first. If we cannot find it, update
    % cache and try again
    % ---------------------------


    
    if itemId_m == ""

        error("Link to '" + workItemId + "' cannot be established. " + ...
                " Cannot find the RMI item." + ...
                " Make sure that the target is available for SimPol.");
    end
    
    flag = false;
    for i=1:size(h.matlabAdapter.settings.Targets, 1)
        if isequal(char(extractBetween(itemId_m, "", "|")), h.matlabAdapter.settings.Targets{i})||...
              isequal(char(extractBetween(itemId_m, "", ":")), h.matlabAdapter.settings.Targets{i})||...
              isequal(char(extractBetween(itemId_m, "", ".sldd")), h.matlabAdapter.settings.Targets{i})||...
              isequal(char(extractBetween(itemId_m, "", ".mldatx")), h.matlabAdapter.settings.Targets{i})
            flag = true;
        end
    end
    
    if flag == false
        error("Link to '" + workItemId + "' cannot be established. " + ...
            "The target you are trying to link does not exist in the list of targets. " +...
            "Make sure it's added and try again.");
    end
    
    % Checking if the Simulink model is closed and reopening it if so
    simulinkModelName = char(extractBetween(itemId_m, "", ":"));
    
    if ~isempty( simulinkModelName ) && ~bdIsLoaded(simulinkModelName) 
        % Simulink models are the only RMI item that contain a semi-colon
        % so checking if simulink model name is not empty is equivalent to
        % checking if it's a simulink model
        open(simulinkModelName);
        h.notifyStatus("Reloaded model '" + string(simulinkModelName) + ...
            ".slx' as it was closed.");
    end

    % For test files, we want to add relative paths as description
    % ---------------------------

    if strcmpi(h.settings.TargetType,"simpol.adapter.RMISimulinkTestAdapter")
        description= h.matlabAdapter.getCachedItem(itemId_m).optional('path');
    else
        description = "";
    end

    data = struct("url", string(h.matlabAdapter.getNavURL(char(itemId_m))),...
        "mItemId", itemId_m,...
        "description", string(description),...
        "imagePath", "",...
        "imageChecksum", "");

    % Create link on polarion side
    % ---------------------------
    [bAddedLink, linkItemId] = h.linkModel.addLinkToSimulink(...
        h.polarionAdapter, h.matlabAdapter, workItemId, data);

    if bAddedLink
        polItem = h.polarionAdapter.getCachedItem(workItemId);
        
        % access surrogate work item id, if present
        surrogateId = '';
        if not(strcmp(linkItemId, workItemId))
            surrogateId = linkItemId;
        end

        % append surrogate work item id, if present
        surrogateSuffix = "";
        if not(isempty(surrogateId))
            surrogateSuffix = " via " + string(surrogateId);
        end

        % RMI stuff is old, so better use chars
        data = struct(...
            "doc", string(h.polarionAdapter.sServerURL) + "/",...
            "id",  "@" +  h.polarionAdapter.getHttpUrl(workItemId, true, surrogateId),...
            "description", string(workItemId) + surrogateSuffix,... % RMI Struct Description
            "revision", string(polItem.lastUpdated));

        % Create link on rmi side
        if ~h.matlabAdapter.addLink(itemId_m, workItemId, data)
            error("LinkManager:RMILinkError", ...
                "Could not establish link on simulink side.");
        end

        h.notifyStatus( ...
            "Link between " + workItemId + " and " +  itemId_m + ...
            " successfully created.");

    else
        error("LinkManager:PolarionLinkError", ...
            "Could not establish link on polarion side.");
    end
end
