function updateSettings(h)

    % Delete old adapters and ondemand tables
    % ------------------

    if ~isempty(h.matlabAdapter) && isvalid(h.matlabAdapter)
        delete(h.matlabAdapter);
    end

    if ~isempty(h.polarionAdapter) && isvalid(h.polarionAdapter)
        delete(h.polarionAdapter);
    end         

    % Process settings - set default values of values are missing
    % ----------------
    h.settings = simpol.utils.AllocConfig(h.allocationFilePath);

    % New link model
    % ---------------
    switch(h.settings.LinkModel)
        case 'Direct Linking'
            h.linkModel = simpol.linkmodel.DirectLinkModel();
        case 'Surrogate Linking'
            h.linkModel = simpol.linkmodel.SurrogateLinkModel();
        otherwise
            error('Unknown link model.');
    end

      % New link table with suspicion model
    % ---------------
    switch(h.settings.SuspicionModel)
        case 'AutoSuspect'
            suspicionModel = simpol.suspicion.AutoSuspicionModel();
        case 'Revision'
            suspicionModel = simpol.suspicion.RevisionSuspicionModel();
        otherwise
            error('Unknown link model.');
    end

    h.linkTable.setSuspicionModel(suspicionModel);

    % New polarion adapter
    % -------------------
    h.polarionAdapter = simpol.adapter.PolarionAdapter(h);
    h.polarionAdapter.setServerURL(h.settings.ServerURL);
    h.polarionAdapter.setProjectID(h.settings.ProjectID);
    h.polarionAdapter.setBaseQuery(h.settings.QueryString);
    h.polarionAdapter.setBaseline(h.settings.BaselineRevision);
    h.polarionAdapterNotifyListener = ...
        listener(h.polarionAdapter, 'UserNotificationEvent',...
            @(source, eventData) notify(h, 'UserNotificationEvent', eventData)); % raii
    h.polarionAdapterItemCacheChangedListener = ...
        listener(h.polarionAdapter, 'ItemCacheChangedEvent',...
            @(varargin) h.linkTable.setItemCacheChanged(simpol.SideType.POLARION));            

    % New RMI adapter
    % --------------
    if ~isempty(h.settings.TargetType)
        h.matlabAdapter = feval(h.settings.TargetType, h);
        h.matlabAdapterNotifyListener = ...
            listener(h.matlabAdapter, 'UserNotificationEvent',...
                @(source, eventData) notify(h, 'UserNotificationEvent', eventData)); % raii                
        h.matlabAdapterItemCacheChangedListener = ...
            listener(h.matlabAdapter, 'ItemCacheChangedEvent',...
            @(varargin) h.linkTable.setItemCacheChanged(simpol.SideType.MATLAB));
    end


end 