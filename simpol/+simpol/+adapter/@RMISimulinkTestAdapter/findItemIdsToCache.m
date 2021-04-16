function itemIds = findItemIdsToCache(h)

itemIds = [];

unavailableTargets = [];
for i = 1:numel(h.mgr.settings.Targets)
    
    if h.isTargetAvailable(h.mgr.settings.Targets{i})
        tm = sltest.testmanager.load(h.mgr.settings.Targets{i});
        
        testfilename = [tm.Name '.mldatx'];
        
        % Search for object with ID
        ids = getNestedTestElementsRecursive([], tm);
        
        sarray = string(ids);
        sarray = string(testfilename) + '|' + sarray;
        ids = sarray.cellstr;
        itemIds = [itemIds ids];
    else
        unavailableTargets{end+1} = h.mgr.settings.Targets{i};
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

itemIds = itemIds';

end

% -------------------------------------------------------------------------

function ids = getNestedTestElementsRecursive(ids, te)

ids{end+1} = te.getProperty('uuid');

nestedTes = {};
if isa(te, 'sltest.testmanager.TestSuite') || isa(te, 'sltest.testmanager.TestFile')
    nestedTes = te.getTestSuites();
end

if isa(te, 'sltest.testmanager.TestSuite')
    tcs = te.getTestCases();
    for i = 1:numel(tcs)
        ids = getNestedTestElementsRecursive(ids, tcs(i));
    end
end

if isa(te, 'sltest.testmanager.TestCase') && ~verLessThan('Simulinktest','3.0')
    titr = te.getIterations();
    for i = 1:numel(titr)
        ids{end+1} = titr(i).saveobj.IterUUID;
    end
end

for i = 1:numel(nestedTes)
    ids = getNestedTestElementsRecursive(ids, nestedTes(i));
end
end