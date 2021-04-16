function item = createItem(h, itemId)
% createItem See base class description. Creates a internal
% data item out of the Simulink Data Item.

item = simpol.data.Item();

item.id = itemId;

[~, entryname] = h.splitId(itemId);

item.name = entryname;
end