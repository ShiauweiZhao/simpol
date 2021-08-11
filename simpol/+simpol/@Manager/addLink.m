function addLink(h, workItemId, destItemId)

    h.ensureIsWritable();
    h.polarionAdapter.ensureOpenSession;

    % Check if mItemId exists first. If we cannot find it, update
    % cache and try again
    % ---------------------------

    URL = h.matlabAdapter.getNavURL(char(destItemId));
    
    itemId_m = convertCharsToStrings(...
        h.matlabAdapter.resolveLink(URL));

    if itemId_m == ""

        h.matlabAdapter.updateCache();

        itemId_m = convertCharsToStrings(...
            h.matlabAdapter.resolveLink(URL));

        if itemId_m == ""

            error("Link to '" + workItemId + "' cannot be established. " + ...
                " Cannot find the RMI item." + ...
                " Make sure that the target is available for SimPol.");
        end
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

    if h.linkModel.addLinkToSimulink(...
            h.polarionAdapter, h.matlabAdapter, workItemId, data)

        polItem = h.polarionAdapter.getCachedItem(workItemId);

        % RMI stuff is old, so better use chars
        data = struct(...
            "doc", string(h.polarionAdapter.sServerURL) + "/",...
            "id",  "@" +  h.polarionAdapter.getHttpUrl(workItemId, true),...
            "description", string(workItemId),... % RMI Struct Description
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