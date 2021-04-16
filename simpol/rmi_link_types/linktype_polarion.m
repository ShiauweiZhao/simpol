function linkType = linktype_polarion
%linktype_TEMPLATE - Template for implementing a custom link type
%
% This file explains how to implement a custom link type to support
% requirements linking between Simulink and a custom requirements
% management application.
% 
% Save this file with a modified name on your MATLAB path, provide string
% attributes and member functions as described below, and then register this
% new custom linktype with the following command:
% 
% >> rmi('register', 'linktype_fileame')
% 
% You must register a custom requirement link type before using it.
% Once registered, the link type will be reloaded in subsequent
% sessions until you unregister it.  
%
% Unregister like this:
% >> rmi('unregister', 'linktype_filename')
%

%  Copyright 2011-2014 The MathWorks, Inc.
%  

    % Create a default (blank) requirement link type 
    linkType = ReqMgr.LinkType;

    %%%%%%%%%%%%%%
    % ATTRIBUTES %
    %%%%%%%%%%%%%%
    
    % Registration attribute is the name of the file that creates the
    % object. Registration name is stored in the requirement link structure to
    % uniquely identify the link type.
    linkType.Registration = mfilename;

    % Label for this link type to be displayed in menus and dialogs
    linkType.Label = 'Polarion Link';

    % Is there a physical file on the hard drive for each document of your
    % custom type? Set to 0 if No.
    linkType.IsFile = 0;  
    
    % If target documents are files, list possible extensions.
    % You may list more than one.
    % In the example below, the 'document' field in the requirement link
    % structure will expect strings like DOCNAME.ext1 or DOCNAME.ext2,
    % the Browse dialog will filter the file list accordingly.
    linkType.Extensions = {}; % = {'.ext1', '.ext2'}

    % Location delimiters.
    % Link target is identified by the document name and the location ID.
    % The first character in the .id field has the special purpose of
    % defining the type of identifier in the rest of the field. Your custom
    % document type may support the following location types:
    %
    %     ? - Search text located somewhere in the document
    %     @ - Named item such as a requirement object ID, etc.
    %     # - Page number or item number  
    %     > - Line number
    %     $ - Sheet range for a spreadsheet
    linkType.LocDelimiters = '@';
    
    % Version id for custom extensions, not currently used
    %linkType.Version = ''; 

    % For document types that support selection-based linking:
    %
    % Specify what label to display in context menus for the 
    % selection-based linking shortcut. Define only if 
    % your custom document type supports selection-based
    % linking. You will also need to define the SelectionLinkFcn 
    % method, see below.
    linkType.SelectionLinkLabel = 'Link to Selection in SimPol';
    

    %%%%%%%%%%%
    % METHODS %
    %%%%%%%%%%%
    
    % Implementation for NavigateFcn must be provided, see example below.
    linkType.NavigateFcn = @NavigateFcn;
    
    % All other member functions are optional. 
    % Uncomment and provide implementation as required.
    %
    linkType.ContentsFcn = @ContentsFcn;       % for document index
    %linkType.BrowseFcn = @BrowseFcn;           % choose a document
    %linkType.CreateURLFcn = @CreateURLFcn;     % for portable links
    linkType.IsValidDocFcn = @IsValidDocFcn;   % for consistency checking
    linkType.IsValidIdFcn = @IsValidIdFcn;     % for consistency checking
    linkType.IsValidDescFcn = @IsValidDescFcn; % for consistency checking
    %linkType.DetailsFcn = @DetailsFcn;         % for detailed report
    
    % SelectinkLinkFcn is called the first time of import to get the struct
    linkType.SelectionLinkFcn = @SelectionLinkFcn;
    
    % Callbacks of the new requirement interface
    if ~verLessThan('matlab', '9.3')
        linkType.HtmlViewFcn = @HtmlViewFcn;
        linkType.GetAttributeFcn = @GetAttributeFcn;
    end
    
    
end

%% function NavigateFcn(DOCUMENT, LOCATION)
    % Open 'document' and highlight or zoom into 'location'
function NavigateFcn(sDocument, sLocation)

    mgr = getSimPolManager();
    
    if ~isempty(sLocation)
        p = simpol.utils.PolarionURLParser(sLocation);
        workItemId = char(p.getWorkItemId());        
        if ~isempty(mgr.polarionAdapter.getCachedItem(workItemId))
            mgr.polarionAdapter.show(workItemId);
        end
    end
end

function [labels, depths, locations] = ContentsFcn(sDocument, options) %#ok<*DEFNU>
    % Used to display the document index tab of Link Editor dialog.
    % You can select an entry in Document Index list to create a
    % link. Should return cell arrays of unique LOCATIONS IDs and text
    % LABELS in matching order. DEPTHS is the same length array of
    % integers to convey parent-child relationships between LABELS, fill
    % with zeros if all locations are same depth.
    
    mgr = getSimPolManager();
        
    
    labels = [];
    locations = [];   
    
    if ~isempty(mgr.polarionAdapter)
        items = mgr.polarionAdapter.cachedItems.values();
        
        for i = 1:numel(items)
            labels{end+1} = items{i}.id;
            locations{end+1} = ['@' mgr.polarionAdapter.getHttpUrl(items{i}.id, true)];
        end

        depths = zeros(1, numel(labels));
    end
end

% function DOCUMENT = BrowseFcn()
%     % Allows users to select a DOCUMENT via Browse button of Link Editor
%     % dialog. Not required when linkType.isFile is true; a standard file
%     % chooser is used filtered based on linkType.Extensions.
%     [filename, pathname] = uigetfile({...
%         '.ext1', 'My Custom Doc sub-type1'; ...
%         '.ext2', 'My Custom Doc sub-type2'}, ...
%         'Pick a requirement file');
%     DOCUMENT = fullfile(pathname, filename);
% end
% 
% function URL = CreateURLFcn(DOCPATH, DOCURL, LOCATION)
%     % Construct a URL to a LOCATION in corresponding document,
%     % for example:
%     if ~isempty(DOCURL)
%         URL = [DOCURL '#' LOCATION(2:end)];
%     else
%         URL = ['file:///' DOCPATH '#' LOCATION(2:end)];
%     end
% end
% 
function SUCCESS = IsValidDocFcn(sDocument, sRefPath)
    % Used for requirements consistency checking.
    % Returns true if DOCUMENT can be located.
    % Returns false if DOCUMENT name is invalid or not found, for example:
    
    mgr = getSimPolManager();
    
    if endsWith(sDocument, '/')
        sDocument = sDocument(1:end-1);
    end
    
    adapterURL = mgr.polarionAdapter.sServerURL;
    if endsWith(adapterURL, '/')
        adapterURL = adapterURL(1:end-1);
    end
    
    SUCCESS = strcmp(sDocument, adapterURL);
end

function SUCCESS = IsValidIdFcn(sDocument, sLocation)
    % Used for requirements consistency checking.
    % Returns true if LOCATION can be found in DOCUMENT.
    % Returns false if LOCATION is not found. 
    % Should generate an error if DOCUMENT not found or fails to open.
    
    mgr = getSimPolManager();
    
    p = simpol.utils.PolarionURLParser(sLocation);
    polItemId = char(p.getWorkItemId());

    if ~isempty(polItemId) && ~isempty(mgr.polarionAdapter.getCachedItem(polItemId))
        SUCCESS = true;
    else
        SUCCESS = false;
    end
end

function [ SUCCESS, DOC_DESCRIPTION ] = IsValidDescFcn(sDocument, sLocation, sDescription)
    % SUCCESS is true if LINK_DESCRIPTION is the string found at LOCATION
    % in DOCUMENT. 
    % DOC_DESCRIPTION is empty if true.
    % DOC_DESCRIPTION is the string found at the location if not SUCCESS.
    % Should generate an error if DOCUMENT is not found or if LOCATION is
    % not found in DOCUMENT.
    
    % Import some stuff we additionally need

    
    SUCCESS = true;
    DOC_DESCRIPTION = '';


end
% 
% function [ DEPTHS, ITEMS ] = DetailsFcn(DOCUMENT, LOCATION, LEVEL)
%     % Return related contents from the DOCUMENT. For example, if
%     % LOCATION points to a section header, this function should try to
%     % return the entire header and body text of the subsection.
%     % ITEMS is a cell array of formatted fragments (tables, paragraphs,
%     % etc.)  DEPTHS is the corresponding numeric array that describes
%     % hierarchical relationship among items.
%     % LEVEL is meant for "details level", not currently used.
%     % Invoked when generating report.
%     ITEMS = {'DetailsFcn not implemented', 'Need to query the document'};
%     DEPTHS = [0 1];
% end
% 
function reqstruct = SelectionLinkFcn(targets, bMake2Way)
    % Returns the requirement info structure determined by the current
    % selection in currently open document of this custom type.
    % 'MAKE2WAY' is a Boolean argument to specify whether navigation
    % control back to OBJECT is inserted in document.
    reqstruct = [];
    
    mgr = getSimPolManager();
    
    % If targets is empty, it is called by by import function!
    if isempty(targets)  
        if ~isempty(mgr.polarionAdapter)

            reqstruct = rmi('createempty');
            reqstruct.doc = [mgr.polarionAdapter.sServerURL '/'];

        end    
    else % If targes is valid, we can try to link
        workItemId = mgr.hSimPolGUI.getSelectedPolarionItemId();
        if isempty(workItemId)
            error('No work item selected in SimPol.');
        end
        
        % Convert to cell array
        if ~iscell(targets)
            if isnumeric(targets)
                targets = num2cell(targets);
            else
                targets = {targets};
            end
        end
        
        % Treat MATLAB code linking
        if ischar(targets{1})
            splits = strsplit(targets{1}, '|');
            [~, name, ext] = fileparts(splits{1});
            
            if strcmp(ext, '.m') 
                % There are two possibilities:
                % a) The id of the range is passed (if the selection
                % exactly matches a range)
                % b) The selection range is passed. Then we link all named
                % ranges that are fully coverd by the selectionn range.
                
                [~, rangeId] = rmiml.ensureBookmark(splits{1}, splits{2});
                
                mgr.matlabAdapter.updateCache();
                targets{1} = [name ext '|' rangeId];
            end
        end
        rt = sfroot;
        for i = 1:numel(targets)
            
            % Convert to valid targets
            if isnumeric(targets{i})
                obj = rt.find('Handle', targets{i});
                if isempty(obj)
                    obj = rt.find('ID', targets{i});
                end
                
                if ~isempty(obj)
                    targets{i} = Simulink.ID.getSID(obj);
                end
            elseif isa(targets{i}, 'Simulink.DDEAdapter')
                targets{i} = [targets{i}.getSourceName '|Design.' targets{i}.getFullName];
            else
                % REmaining is MATLAB code                
            end
            
            mgr.addLink(workItemId, targets{i})
        end
        mgr.hSimPolGUI.updateItemViews();
    end
    
end

function html = HtmlViewFcn(sDocument, sLocation, x)
    mgr = SimPol('instance');
    
    jItem = mgr.polarionAdapter.getWorkItem(mgr.polarionAdapter.uri2id(sLocation), 'description');
    
    if ~isempty(jItem)
        item = simpol.workitem.PolarionWorkItem(mgr.polarionAdapter, jItem);
        html = item.getHTMLDescription();
    else
        html = '';
    end
end

function value = GetAttributeFcn(moduleId, itemId, attributeName)
value = [];
%     value = rmidoors.getObjAttribute(moduleId, itemId, attributeName);
end

function mgr = ensureCorrectDocument(srcRefH)
    
    % Check handle
    try
       if ischar(srcRefH) % Stateflow, simulink or test file
           if endsWith(string(srcRefH), '.mldatx')
                sltest.testmanager.load(srcRefH);
                srcDoc = srcRefH;
           elseif endsWith(string(srcRefH), '.sldd') % Data dictionary
               Simulink.data.dictionary.open(srcRefH);
               srcDoc = srcRefH;
           else % SID or block path
               blkpath = Simulink.ID.getFullName(srcRefH);
               modelName = bdroot(blkpath);
               mdlInfo = Simulink.MDLInfo(modelName);
               srcDoc = mdlInfo.FileName;
           end
       else % Must be a Simulink or statflow element
           rt = sfroot;
           o = rt.find('Id', srcRefH);
           
           if isempty(o)
                o = get_param(srcRefH, 'object');
           end
           
           modelName = Simulink.ID.getModel(Simulink.ID.getSID(o));
           mdlInfo = Simulink.MDLInfo(modelName);
           srcDoc = mdlInfo.FileName;
       end
        
        
    catch ME
        errordlg('The document type is not supported.');
        error('Not a supported document type.');
    end
    
    if isempty(srcDoc)
        errordlg('The document type is not supported.');
        error('Not a supported document type.');
    end
    
    mgr = SimPol('instance');
    
    if isempty(mgr.polarionAdapter)
       errordlg('No Allocation File loaded.');
       error('SimPol not correctly set up.');
    end

end

function mgr = getSimPolManager()
    
    % Verify that instance exists
    if SimPol('test')
       mgr = SimPol('instance');
    else
        error('SimPol instance cannot be detected.');   
    end
    
    % Verify that Polarion adapter exists
    if isempty(mgr.polarionAdapter)
        error('No allocation file in SimPol loaded.');
    end

end
