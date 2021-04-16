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
            
            targetIds = {[targetFileName targetFileExt]};
            
        else %.slx
            try
                load_system(targetFileName);
                rt = sfroot;
                mdl = rt.find('-isa', 'Simulink.BlockDiagram', '-and',...
                    'Name', targetFileName);
                mblocks = mdl.find('-isa', 'Stateflow.EMChart');
                targetIds = arrayfun(@(x)Simulink.ID.getSID(x), mblocks,...
                    'UniformOutput', false);
            catch
                warning("Cannot find " +  targetFileName + ".");
            end
            
        end
        
        for j = 1:numel(targetIds)
            data = slreq.utils.getRangesAndLabels(which(targetIds{j}));
            for k = 1:size(data,1)
                itemIds = [itemIds; cellstr([targetIds{j} '|' data{k,1}])];
            end
        end
    end
end
end