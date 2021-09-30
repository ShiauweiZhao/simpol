function itemIds = findItemIdsToCache(h)
% FINDITEMIDSTOCACHE Returns the item IDs, i.e., the saved ranges,
% for all targets (MATLAB code files / models with embedded MATLAB code).

itemIds = [];

for i = 1:numel(h.mgr.settings.Targets)
    
    targetFilePath = which(h.mgr.settings.Targets{i});
    
    if isempty(targetFilePath)
        h.notifyWarn("Cannot find target: " +...
            h.mgr.settings.Targets{i} + ". Not on path?");
        break;
    end
    
    [~, targetFileName, targetFileExt] = fileparts(targetFilePath);
    
    if ~isempty(targetFilePath)
        
        if strcmp(targetFileExt, '.m')
            
            targetId = { h.mgr.settings.Targets{i} };
            targetIdExt = targetId;
            
        else %.slx
            try
                load_system(targetFileName);
                rt = sfroot;
                mdl = rt.find('-isa', 'Simulink.BlockDiagram', '-and',...
                    'Name', targetFileName);
                mblocks = mdl.find('-isa', 'Stateflow.EMChart');
                targetIdExt = arrayfun(@(x)Simulink.ID.getSID(x), mblocks,...
                    'UniformOutput', false);
                targetId = targetIdExt;
            catch
                warning("Cannot find " +  targetFileName + ".");
            end
            
        end
        
        for j = 1:numel(targetIdExt)
            data = slreq.utils.getRangesAndLabels(which(targetId{j}));
            for k = 1:size(data,1)
                itemIds = [itemIds; cellstr([targetIdExt{j} '|' data{k,1}])]; %#ok<AGROW>
            end
        end
    end
end
end