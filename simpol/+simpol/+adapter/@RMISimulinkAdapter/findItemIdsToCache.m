function itemIds = findItemIdsToCache(h)

    if ~isempty(h.mgr.settings) && isfield(h.mgr.settings, 'SLSFSelectionRule') &&...
            ~isempty(h.mgr.settings.SLSFSelectionRule)
        fun = h.mgr.settings.SLSFSelectionRule;
    else
        fun = 'simpol_SLSFSelectionRule';
    end

    % For all targets
    itemIds = [];
    unavailableTargets = [];
    for i = 1:numel(h.mgr.settings.Targets)
        if h.isTargetAvailable(h.mgr.settings.Targets{i})
            h.notifyStatus("Caching model " + h.mgr.settings.Targets{i});
            itemIds = [itemIds; feval(fun,h.mgr.settings.Targets{i})]; %#ok<AGROW>
        else
            unavailableTargets{end+1} = h.mgr.settings.Targets{i}; %#ok<AGROW>
        end
    end

    if ~isempty(unavailableTargets)
        h.notifyWarn(...
            "The following targets specified " + ...
            "in the configuration cannot be found: " + newline + newline +...
            strjoin("- " + unavailableTargets, newline) + newline + newline + ...
            "Make sure these models exist and are on the search path.",...
            "Target missing");
    end

end