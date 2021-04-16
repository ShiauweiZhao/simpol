function itemIds = findItemIdsToCache(h)
    % For all targets
    itemIds = [];
    for i = 1:numel(h.mgr.settings.Targets)

        sldd = Simulink.data.dictionary.open([h.mgr.settings.Targets{i} '.sldd']);
        section = sldd.getSection('Design Data');

        allEntries = section.find();

        names = string(h.mgr.settings.Targets{i}) +  '.sldd|Design.' + {allEntries.Name};

        itemIds = [itemIds; cellstr(names')];
    end
end