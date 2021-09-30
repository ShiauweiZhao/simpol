function item = createItem(h, itemId)
% createItem Creates an internal data item for the test object
% with ID.

item = simpol.data.Item();
item.id = itemId;
% fullID paramter is a workaround for MATLAB adapter, here is just id copy
item.fullID = itemId;  

tm = sltest.testmanager.load(strtok(itemId, '|'));

testfilename = [tm.Name '.mldatx'];

% Search for object with ID
if strcmp(h.getTestObjectID(testfilename, tm), itemId)
    to = tm;
    parentTo = [];
    path = to.Name;
else
    [to, path, parentObj] = searchTestElementsRecursive(...
        [], tm, extractAfter(itemId, '|'));
    parentTo = parentObj;
end

if isempty(to)
    item.name = ['<unresolvable>' num2str(itemId)];
    
else
    item.name = to.Name;
end

item.optional('path') = path;
% Get parents
if ~isempty(parentTo)
    item.parentWorkItemIds = {h.getTestObjectID(testfilename, parentTo)};
end
end

 % -----------------------------------------------------------------
  
function [obj, path, parentObj] =...
        searchTestElementsRecursive(obj, te, uuid)
    % searchTestElementsRecursive Helper function to search for a
    % test element wiht a given UUID recursively.

    path = '';
    parentObj = [];
    if ~isa(te, 'sltest.testmanager.TestIteration') &&...
            ~isa(te, 'sltest.testmanager.TestFile')
        path = te.TestPath;
        parentObj = te.Parent;
    end

    if strcmp(uuid, te.getProperty('uuid'))
        obj = te;
        return;
    end

    nestedTes = {};
    if isa(te, 'sltest.testmanager.TestSuite') ||...
            isa(te, 'sltest.testmanager.TestFile')
        nestedTes = te.getTestSuites();
    end

    if isa(te, 'sltest.testmanager.TestSuite')
        tcs = te.getTestCases();
        for i = 1:numel(tcs)
            [obj,path, parentObj] =...
                searchTestElementsRecursive(obj, tcs(i), uuid);
            if ~isempty(obj)
                return;
            end
        end
    end

    if isa(te, 'sltest.testmanager.TestCase') && ~verLessThan('Simulinktest','3.0')
        tcPath=te.TestPath;
        titr = te.getIterations();
        for i = 1:numel(titr)
            if strcmp(uuid, titr(i).saveobj.IterUUID)
                obj = titr(i);
                path=[tcPath ' > ' titr(i).Name];
                parentObj=te;
                return;
            end

        end
    end

    for i = 1:numel(nestedTes)
        [obj,path, parentObj] = searchTestElementsRecursive(obj, nestedTes(i), uuid);
        if ~isempty(obj)
            return;
        end
    end
end