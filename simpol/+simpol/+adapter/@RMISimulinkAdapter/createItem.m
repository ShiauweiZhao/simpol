function item = createItem(~, itemId)
% createItem Creates an internal data item out from the block describted by
% itemId. ItemId is the SID of the block.

item = simpol.data.Item();
item.id = itemId;
% fullID paramter is a workaround for MATLAB adapter, here is just id copy
item.fullID = itemId;  

try
    load_system(Simulink.ID.getModel(itemId));
    
    ho = Simulink.ID.getHandle(itemId);
    if isnumeric(ho) % If simulink
        item.name = get_param(itemId, 'Name');
    else
        if isa(ho, 'Stateflow.State')
            item.name = "State: " + ho.Name;
        elseif isa(ho, 'Stateflow.Transition')
            item.name = "Transition: " + ho.LabelString;
        elseif isa(ho, 'Stateflow.Box')
            item.name = "Box: " + ho.LabelString;
        elseif isa(ho, 'Stateflow.Function')
            item.name = "Function: " +  ho.Name;
        else
            item.name = ho.Path;
        end
        item.name = item.name + "(" + itemId + ")";
    end
catch
    item.name = "<unloaded> " + itemId;
    return;
end

% Get parents
% This only works since sids does not contain blocks in referenced
% libraries. Otherwise, they would also have more than one semi-colon in
% the SID.
numSemiColons = length(strfind(itemId, ':'));
isSL = numSemiColons == 1;
isSF = numSemiColons > 1;

if isSL
    item.parentWorkItemIds = {Simulink.ID.getSID(get_param(itemId, 'Parent'))};
elseif isSF
    item.parentWorkItemIds = {Simulink.ID.getSID(Simulink.ID.getHandle(itemId).getParent())};
end

end