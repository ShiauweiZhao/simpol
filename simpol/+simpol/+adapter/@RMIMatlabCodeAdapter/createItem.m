function item = createItem(h, itemId)
% createItem Creates an internal data item out from the code range describted by
% itemId.

item = simpol.data.Item();
item.id = itemId;

splits = strsplit(itemId, '|');
data = slreq.utils.getRangesAndLabels(which(splits{1}));
idx = find(strcmp(data(:,1), splits{2}), 1, 'first');
bookmarkRange=[data{idx,2:3}];
rowRange= bookmarkToRow(which(splits{1}), bookmarkRange);

try
    text = rmiml.getText(splits{1}, splits{2});
catch
    text = '';
end

textSnip = '';
if ~isempty(text)
    textSnip = text(1:min(20, strlength(text)));
end

if contains(splits{1}, ':')
    docName = [bdroot(splits{1}) '/../' get_param(splits{1}, 'Name')];
else
    docName = splits{1};
end

item.name = [docName ' [' num2str(rowRange(1)) '-' num2str(rowRange(2)) '] ' textSnip '...'];
end

function rows = bookmarkToRow(target, bookmarkRange)
    fullText = rmiml.getText(target);
    linePositions = find(fullText == 10);
    bookmarkText = rmiml.getText(target, bookmarkRange);
    selectedCRs = find(bookmarkText == 10);
    numberOfLinesBefore = sum(linePositions < bookmarkRange(1));
    rows = [numberOfLinesBefore+1 numberOfLinesBefore+length(selectedCRs)+1];
end

