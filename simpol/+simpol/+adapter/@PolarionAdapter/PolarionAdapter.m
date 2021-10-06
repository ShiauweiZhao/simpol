classdef PolarionAdapter < simpol.adapter.AbstractAdapter
    % PolarionAdapter Provides adapter functions for Polarion Web Service
    % API.
    
    properties(Access=private)
        sUserName = '';   
        sUserPassword = [];
    end
    
    properties(SetAccess=private, GetAccess=public)
        sServerURL = ''; % Always without ending slash
        sProjectID = '';
        sBaseQuery = '';
        sBaselineRevision = '';
        dirtySession = false;
        sessionService;
        trackerService;
        securityService;
        projectService;
    end
    
    properties(Constant, Access=private)
        queryFields = {'id', 'title','hyperlinks',...
            'linkedWorkItemsDerived', 'linkedWorkItems', 'updated','description'};
    end
    
    methods(Static)
        function name = getName()
            name = 'Polarion';
        end
        
        function iconFileName = getItemIcon(~)
            iconFileName = 'simpol_req.png';
        end
        
        function side = getSide()
            side = simpol.SideType.POLARION;
        end
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods
        
        function h = PolarionAdapter(mgr)
            h = h@simpol.adapter.AbstractAdapter(mgr);
        end
        
        % -----------------------------------------------------------------
        
        function s = getHttpUrl(h, uri_id, bRelative, via_id)
            
            uri_id = convertStringsToChars(uri_id);
            
            s = '';
            
            if nargin < 3
                bRelative = false;
            end
            
            if isempty(uri_id) || ~ischar(uri_id)
                return;
            end
            
            % Create relative url
            if uri_id(1) == '@'
                s = uri_id(2:end);
            else
                s = ['/project/' h.sProjectID '/workitem?id=' uri_id];
            end
            
            % Append surrogate id if available
            if nargin > 3 && ~isempty(via_id) && ~contains(s, 'via=')
                % TODO
                s = [s '&via=' via_id];
            end
            
            % Add baseline
            if ~isempty(h.sBaselineRevision)
                s = ['/baseline/' h.sBaselineRevision s];
            end
            
            if ~bRelative
                s = [h.sServerURL '/#' s];
            end
            
        end
        
        % -----------------------------------------------------------------
        
        function setServerURL(h, sServerURL)
            if string(sServerURL).endsWith('/')
                h.sServerURL = sServerURL(1:end-1);
            else
                h.sServerURL = sServerURL;
            end
            
            h.updateServices();
            
            h.dirtySession = true;
        end
        
        % -----------------------------------------------------------------
        
        function setProjectID(h, sProjectID)
            h.sProjectID = sProjectID;
        end
        
        % -----------------------------------------------------------------
        
        function setBaseQuery(h, sBaseQuery)
            h.sBaseQuery = sBaseQuery;
        end
        
        % -----------------------------------------------------------------
        
        function setCredentials(h, sUserName, sUserPassword)
            h.sUserName = sUserName;
            h.sUserPassword = sUserPassword;
            h.dirtySession = true;
        end
        
        % -----------------------------------------------------------------
        
        function setBaseline(h, baselineRevision)
            
            % if format name ( )
            if ~isempty(baselineRevision) && isnan(str2double(baselineRevision))
                tmp = regexp(baselineRevision, '\((.*?)\)', 'match');
                if isempty(tmp) || length(tmp{1}) < 3
                    error(['Invalid baseline ' baselineRevision]);
                end
                tmp = tmp{1};
                tmp = tmp(2:end-1);
                h.sBaselineRevision = tmp;
            else
                h.sBaselineRevision = baselineRevision;
            end
            
            h.dirtySession = true;
        end
        
        % -----------------------------------------------------------------
        
        function updateServices(h)
            
            if isempty(h.sServerURL)
                if ~isempty(h.sessionService) && h.sessionService.hasSubject()
                    h.endSession();
                end
                h.sessionService = [];
                h.trackerService = [];
                
            else
                
                % Make java objects
                h.notifyStatus('Checking URL...');
                try
                  u = java.net.URL(char(h.sServerURL));
                  conn = u.openConnection;
                  conn.connect();
                  conn.disconnect();
                catch e
                    h.notifyStatus(e.message);
                    error('PolarionAdapter:ServerUnavailable', 'Cannot read from server. Check your internet connection.');
                end
                
                % Open services
                wsfactory = com.polarion.alm.ws.client.WebServiceFactory(...
                    h.getServiceURL());
                
                h.sessionService = wsfactory.getSessionService();
                h.trackerService = wsfactory.getTrackerService();
                h.projectService = wsfactory.getProjectService();
                h.securityService = wsfactory.getSecurityService();
            end
        end
                
        % -----------------------------------------------------------------
        
        function [names, revisions] = getBaselines(h)
            names = [];
            revisions = [];
            
            h.ensureOpenSession();
            
            baselines = h.trackerService.queryBaselines(...
                ['project.id:' h.sProjectID], 'Revision');
            
            if ~isempty(baselines)
                names = arrayfun(@(x) char(x.getName()), baselines,...
                    'UniformOutput', false);
                revisions = arrayfun(@(x) char(x.getBaseRevision()), baselines,...
                    'UniformOutput', false);
            end
        end
        
        % -----------------------------------------------------------------
        
        function show(h, itemId)
            web(h.getHttpUrl(itemId, false), '-browser');
        end
        
        % -----------------------------------------------------------------
        
        function delete(h)
            h.endSession();
        end
        
        % -----------------------------------------------------------------
        
        function updateCacheImpl(h)
            
            h.cachedItems.remove(h.cachedItems.keys());
            
            h.ensureOpenSession();
            
            h.notifyStatus("Performing query...");
            
            if isempty(h.sBaselineRevision)
                jItems = h.trackerService.queryWorkItems(...
                    h.getQueryString(),...
                    'id', ...
                    h.queryFields);
            else
                jItems = h.trackerService.queryWorkItemsInBaseline(...
                    h.getQueryString(),...
                    'id', ...
                    h.sBaselineRevision,...
                    h.queryFields);
            end
            
            if isempty(jItems)
                return;
            end
            
            h.notifyStatus("Queried " + numel(jItems) + " work item(s)...");
            
            for i = 1:jItems.length()
                jItem = jItems(i);
  
                if ~isempty(jItem)                    
                    h.updateCachedItemFromJWorkItem(jItem);
                end
            end
            
            h.notifyStatus("Cached " + h.cachedItems.Count + ...
                " work item(s)...");
        end
        
        % -----------------------------------------------------------------
        
        function updateCachedItemFromJWorkItem(h, jItem)
            item = h.createItem(jItem);
            
            if isempty(item.id)
                % Work items without IDs are probably not readable.
                % Check with h.securityService.canReadInstance(item.getUri())
                % is possible, but slow.                
                h.notifyStatus("Cannot read work item " + string(jItem.getUri()) + ...
                    " (probably due to missing access rights). Skipped."); 
                return;
            end
            
            % Get links depending on the link model
            item.links = h.linkModel.getLinks(h, item, jItem);             

            h.cachedItems(item.id) = item;
        end
        
        % -----------------------------------------------------------------
        
        function updateCachedItemImpl(h,itemId)
   
            h.notifyStatus("Getting work item...");

            if isempty(h.sBaselineRevision)
                jItem = h.trackerService.getWorkItemByIdsWithFields(...
                    h.sProjectID, itemId, h.queryFields);
            else
                jItem = h.trackerService.getWorkItemByUriInRevisionWithFields(...
                    h.id2uri(itemId), h.sBaselineRevision, h.queryFields);
            end

            if ~isempty(jItem)
                h.updateCachedItemFromJWorkItem(jItem);
            end

            h.notifyStatus("Cached workitem " +  itemId + "...");
        end

    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods(Access=public)
        
        % Queries a working item with workItemID and fields
        function jWorkItem = getWorkItem(h, workItemId, fields)
            
            jWorkItem = [];
            
            h.ensureOpenSession();
            
            if ~h.sessionService.hasSubject()
                return;
            end
            
            workItemUri = h.id2uri(workItemId); % If is uri, no change, otherwise uri
            
            if nargin == 2
                if isempty(h.sBaselineRevision)
                    jWorkItem = h.trackerService.getWorkItemByUri(workItemUri);
                else
                    jWorkItem = h.trackerService.getWorkItemByUriInRevision(workItemUri, h.sBaselineRevision);
                end
            else
                if isempty(h.sBaselineRevision)
                    jWorkItem = h.trackerService.getWorkItemByUriWithFields(workItemUri, fields);
                else
                    jWorkItem = h.trackerService.getWorkItemByUriInRevisionWithFields(workItemUri, h.sBaselineRevision, fields);
                end
                
            end
            
            if isempty(jWorkItem) || isempty(jWorkItem.getUri()) || jWorkItem.isUnresolvable
                jWorkItem = [];
            end
            
        end
        
        % -----------------------------------------------------------------
        
        function jWorkItems = queryWorkItems(h, queryString, sortField, fields)
            h.ensureOpenSession();
            
            if ~h.sessionService.hasSubject()
                return;
            end
            
            if isempty(h.sBaselineRevision)
                jWorkItems = h.trackerService.queryWorkItems(queryString, sortField, fields);
            else
                jWorkItems = h.trackerService.queryWorkItemsInBaseline(queryString, h.sBaselineRevision, sortField, fields);
            end
        end
        
        % -----------------------------------------------------------------
        
        function pushWorkItem(h, jWorkItem)
            
            h.ensureOpenSession();
            
            h.trackerService.updateWorkItem(jWorkItem);
            
        end
        
        % -----------------------------------------------------------------
        
        function jWorkItem = toWorkItem(h, type, varargin)
            p = inputParser;
            p.addParameter('title', '');
            p.addParameter('description', '');
            p.parse(varargin{:});
            
            title = convertStringsToChars(p.Results.title);
            description = convertStringsToChars(p.Results.description);
            
            jWorkItem = com.polarion.alm.ws.client.types.tracker.WorkItem;
            jWorkItem.setType(com.polarion.alm.ws.client.types.tracker.EnumOptionId(...
                type));
            
            if ~isempty(title)
                jWorkItem.setTitle(title);
            end
            
            if ~isempty(description)
                t = com.polarion.alm.ws.client.types.Text('text/html', description, false);
                jWorkItem.setDescription(t);
            end
            
            jProject = h.projectService.getProject(h.sProjectID);
            jWorkItem.setProject(jProject);
            
        end
        
        % -----------------------------------------------------------------
        
        %  Creates a new working item and returns ID and URI
        function [id, uri] = createWorkItem(h, jWorkItem)
            
            h.notifyStatus("Creating new work item work item...");
            
            h.ensureOpenSession();
            
            uri = char(h.trackerService.createWorkItem(jWorkItem));
            
            id = uri(strfind(uri, '{WorkItem}')+10:end);
            
            h.notifyStatus("Created new work item with ID " + id + "...");
        end
        
        % -----------------------------------------------------------------        
        
        function b = addWorkItemLink(h, item, targetItemId, role)
            
            h.ensureIsWritable();
            
            h.notifyStatus("Adding link to work item...");
            
            role = com.polarion.alm.ws.client.types.tracker.EnumOptionId(role);
            
            h.ensureOpenSession();
            
            % If item is only the ID, we have to load the work item form
            % the server
            if ischar(item)
                item = h.getWorkItem(item, {'linkedWorkItems'});
            end
            
            targetItemUri = h.id2uri(targetItemId);
            
            wilinks = item.getLinkedWorkItems();
            idxLink = 0;
            
            for i = 1:numel(wilinks)
                if strcmp(char(wilinks(i).getWorkItemURI()), targetItemUri) && ...
                        strcmp(char(wilinks(i).getRole().getId()), h.mgr.settings.SurrogateLinkRole)
                    idxLink = i;
                    break;
                end
            end
            
            if idxLink == 0
                b = h.trackerService.addLinkedItem(char(item.getUri()), targetItemUri, role);
            else
                b = true;
            end
            
            h.notifyStatus("Link to work item added successfully ...");
            
        end
        
        % -----------------------------------------------------------------
        
        function b = removeWorkItemLink(h, itemId, targetItemId, role)
            
            h.ensureIsWritable();
            
            h.ensureOpenSession();
            
            srcItemUri = h.id2uri(itemId);
            targetItemUri = h.id2uri(targetItemId);
            
            h.trackerService.removeLinkedItem(srcItemUri, targetItemUri, ...
                com.polarion.alm.ws.client.types.tracker.EnumOptionId(role));
            
            b = true;
        end
        
        % -----------------------------------------------------------------
        
        function [bSuccess, idxHyperlink] = addHyperlink(h, item, url)
            % Adds a new hyperlink, but only if it doesn't exist yet.
            % Returns true, if the hyperlink exists after the call - no matter
            % if it has been created or already existed
            
            bSuccess = false;
            
            url = convertCharsToStrings(url);
            
            % Checking that the url is not empty is very important. Otherwise
            % you get dead, invisble links in Polarion.
            if isempty(url) || url == ""
                error('URL to create hyperlink must be a non-empty string.');
            end
            
            % Only allow adding hyperlink if the tool is in writable mode
            h.ensureIsWritable();
            
            % Force open session
            h.ensureOpenSession();
            
            % If item is only the ID, we have to load the work item form
            % the server
            if ischar(item)
                item = h.getWorkItem(item, {'hyperlink'});
            end
            
            if isempty(item) || isempty(item.getUri())
                return;
            end
            
            % Get index of hyperlink by searching for the respective URL
            % Index of hyperlink is 0, if not existing
            idxHyperlink = 0;
            
            hyperlinks = item.getHyperlinks();
            for i = 1:hyperlinks.length()
                if strcmp(char(hyperlinks(i).getUri()), url)
                    idxHyperlink = i;
                    break;
                end
            end
            
            % If the hyperlink does not exist yet, add a new one
            if idxHyperlink == 0
                
                h.notifyStatus("Adding new hyperlink to work item...");
                
                h.trackerService.addHyperlink(item.getUri(), url, ...
                    com.polarion.alm.ws.client.types.tracker.EnumOptionId('ref_ext'));
                
                h.notifyStatus("Link successfully added to work item.");
                
                % Return new index
                idxHyperlink = hyperlinks.length() + 1;
                
            else
                h.notifyStatus("Hyperlink not added since already existing.");
            end
            
            bSuccess = true;
        end
        
        % -----------------------------------------------------------------
        
        % Removes a hyperlink by  url (= identifier).
        % Throws and error cannot be connected or returns fails of
        % something wents wrong
        function [b, url] = removeHyperlink(h, item, identifier)
            % Identifier may either be the URL or index
            
            b = false;
            url = [];
            
            h.ensureIsWritable();
            h.ensureOpenSession();
            
            h.notifyStatus("Removing hyperlink from work item...");
            
            if ischar(item) || isstring(item)
                jItem = h.getWorkItem(item, {'hyperlinks'});
            end
            
            if ischar(identifier) || isstring(identifier)
                linkId = convertCharsToStrings(identifier);
                splits = strsplit(linkId, "|");
                url = splits(end);
            elseif isnumeric(identifier)
                hyperlinks = jItem.getHyperlinks();
                if numel(hyperlinks) >= identifier
                    url = char(hyperlinks(identifier).getUri());
                else
                    return;
                end
            else
                error('Identifier must be either a char or numeric.');
            end
                
            b = h.trackerService.removeHyperlink(item.getUri(), url);
            
            if b
                h.notifyStatus("Hyperlink successfully removed from work item...");
            else
                h.notifyStatus("Hyperlink could not be removed from work item...");
            end

        end
        
        % -----------------------------------------------------------------
        
        function bSuccess = addDescription(h, item, description)
            bSuccess = false;
            
            % Only allow adding description if the tool is in writable mode
            h.ensureIsWritable();
            
            % Force open session
            h.ensureOpenSession();
            
            % If item is only the ID, we have to load the work item form
            % the server
            if ischar(item)
                item = h.getWorkItem(item);
            end
            
            if isempty(item)
                return;
            end

            newItem = com.polarion.alm.ws.client.types.tracker.WorkItem;
            newItem.setUri(item.getUri());
            t = com.polarion.alm.ws.client.types.Text('text/html', description, false);
            newItem.setDescription(t);
            
            % Push new description
            h.pushWorkItem(newItem);
   
            bSuccess=true;
        end
        
        % -----------------------------------------------------------------
        
        function [b, idxAttachment] = addAttachment(h, item, title, fileName, filepath)
            
            b = false;
            idxAttachment = 0;
            
            h.ensureIsWritable();
            
            h.notifyStatus("Uploading image ...");
            
            h.ensureOpenSession();
            
            if ~exist(filepath, 'file')
                return;
            end
            
            % If item is only the ID, we have to load the work item form
            % the server
            if ischar(item)
                item = h.getWorkItem(item, {'attachments'});
            end
            
            if isempty(item) || isempty(item.getUri())
                return;
            end
            
            attachments = item.getAttachments();
            [attachment, idxAttachment] = h.findAttachment(attachments, title);
            
            fid = fopen(filepath);
            data = fread(fid);
            fclose(fid);
            
            if idxAttachment ~= 0
                 h.trackerService.deleteAttachment(item.getUri(), char(attachment.getId()));
            end
            
            h.trackerService.createAttachment(item.getUri(),...
                    fileName, title, data);
                idxAttachment = attachments.length() + 1;
            
            h.notifyStatus("Uploaded image successfully ...");
            
            
            b = true;
            
        end
        
        % -----------------------------------------------------------------
        
        function b = removeAttachment(h, item, title)
            
            b = false;
            
            h.ensureIsWritable();
            
            h.ensureOpenSession();
            
            h.notifyStatus("Removing image ...");
            
            % If item is only the ID, we have to load the work item form
            % the server
            if ischar(item)
                item = h.getWorkItem(item, {'attachments'});
            end
            
            if isempty(item) || isempty(item.getUri())
                return;
            end
            
            attachments = item.getAttachments();
            attachment = h.findAttachment(attachments, title);
            
            if ~isempty(attachment)
                h.trackerService.deleteAttachment(item.getUri(), char(attachment.getId()));
            end
            
            h.notifyStatus("Removed image successfully ...");
            
            b = true;
            
        end
        
        % -----------------------------------------------------------------
        
        function [attachment, idx] = findAttachment(h, attachments, title)
            idx = 0;
            attachment = [];
            
            if isempty(attachments)
                return;
            end
            
            for i = 1:attachments.length()
                if strcmp(char(attachments(i).getTitle()), title)
                    idx = i;
                    attachment = attachments(i);
                    break;
                end
            end
        end
        
        % -----------------------------------------------------------------
        
        function nl = getImageTags(h, xdoc)
            import javax.xml.xpath.*
            xPathFactory = XPathFactory.newInstance();
            xpath = xPathFactory.newXPath();
            nl = xpath.compile(...
                '//img').evaluate(...
                xdoc, XPathConstants.NODESET);
        end
        
        % -----------------------------------------------------------------
        
        function [idxTag, xitem, nTags] = findImageTag(h, doc, imgRef)
            % Check if tag already exists
            
            idxTag = 0;
            xitem = [];
            
            nl = h.getImageTags(doc);
            nTags = nl.getLength();
            for i = 1:nTags
                try
                    imgName = string(nl.item(i-1).getAttributes().getNamedItem('src').getNodeValue());
                    
                    if contains(imgName, imgRef)
                        idxTag = i;
                        xitem = nl.item(i-1);
                        break;
                    end
                catch
                    continue;
                end
            end
        end
        
        % -----------------------------------------------------------------
        
        function [b, idxTag] = addImageTag(h, item, imgRef)
            
            b = false;
            idxTag = 0;
            
            h.ensureIsWritable();
            
            h.ensureOpenSession();
            
            h.notifyStatus("Embedding image ...");
            
            % If item is only the ID, we have to load the work item form
            % the server
            if ischar(item)
                jWorkItem = h.getWorkItem(item, {'description', 'attachments'});
            else
                jWorkItem = item;
            end
            
            if isempty(jWorkItem) || isempty(jWorkItem.getUri())
                return;
            end
            
            import javax.xml.parsers.DocumentBuilder;
            if ~isempty(jWorkItem.getDescription())
                doc = simpol.utils.XML.str2dom(char(jWorkItem.getDescription().getContent()), 'fragment', true); % Parse fragment
            else
                doc = simpol.utils.XML.str2dom('', 'fragment', true);
            end
            
            % We need the ID of the attachment
            attachments = jWorkItem.getAttachments();
            [attachment, ~] = h.findAttachment(attachments, imgRef);            
            
            [idxTag, imgTag, nTags] = findImageTag(h, doc, imgRef);
            
            srcTagValue = ['workitemimg:' char(attachment.getId())];
            
            if idxTag == 0

                imgNode = doc.createElement('img');
                imgNode.setAttribute('src', srcTagValue);
                imgNode.setAttribute('style', 'max-width:800px;');
                imgNode.setAttribute('border', '1');
                
                brNode = doc.createElement('br');
                
                doc.getFirstChild().appendChild(brNode);
                doc.getFirstChild().appendChild(imgNode);
                
                idxTag = nTags + 1;
            else
                imgTag.getAttributes().getNamedItem('src').setNodeValue(srcTagValue);
            end
            
            newDescription = simpol.utils.XML.dom2str(doc, 'fragment', true);
            
            newItem = com.polarion.alm.ws.client.types.tracker.WorkItem;
            newItem.setUri(jWorkItem.getUri());
            t = com.polarion.alm.ws.client.types.Text('text/html', newDescription, false);
            newItem.setDescription(t);
            
            % Push new description
            h.pushWorkItem(newItem);
            
            h.notifyStatus("Embedded image successfully ...");
            
            b = true;
        end
        
        % -----------------------------------------------------------------
        
        function b = removeImageTag(h, item, imgRef)
            
            b = false;
            
            h.ensureIsWritable();
            
            h.notifyStatus("Removing embedded image ...");
            
            h.ensureOpenSession();
            
            
            % If item is only the ID, we have to load the work item form
            % the server
            if ischar(item)
                jWorkItem = h.getWorkItem(item, {'description'});
            else 
                jWorkItem = item;
            end
            
            if isempty(jWorkItem) || isempty(jWorkItem.getUri()) || ...
                    isempty(jWorkItem.getDescription())
                return;
            end
            
            import javax.xml.parsers.DocumentBuilder;
            doc = simpol.utils.XML.str2dom(char(jWorkItem.getDescription.getContent()),...
                'fragment', true); % Parse fragment
            
            [~, imgTagFound] = findImageTag(h, doc, imgRef);
            
            if ~isempty(imgTagFound)
                doc.getFirstChild().removeChild(imgTagFound);
                newDescription = simpol.utils.XML.dom2str(doc, 'fragment', true);
                
                newItem = com.polarion.alm.ws.client.types.tracker.WorkItem;
                newItem.setUri(jWorkItem.getUri());
                t = com.polarion.alm.ws.client.types.Text('text/html', newDescription, false);
                newItem.setDescription(t);
                
                % Push new description
                h.pushWorkItem(newItem);
            end
            
            h.notifyStatus("Removed embedded image ...");
            
            b = true;
        end
        
        % -----------------------------------------------------------------
        
        function b = isReadOnly(h)
            b = ~isempty(h.sBaselineRevision);
        end
        
        % -----------------------------------------------------------------
        
        function s = getQueryString(h)
            s = h.getBaseQueryString();
            
            if ~isempty(h.sBaseQuery)
                s = [s ' AND ' h.sBaseQuery];
            end
        end
        
        % -----------------------------------------------------------------
        
        function s = getBaseQueryString(h)
            s = ['project.id:' h.sProjectID];
        end
        
        % -----------------------------------------------------------------        
        
        % Ensures that a session is open. Throws an error if not.
        function ensureOpenSession(h)          
            
            % End sessions that are dirty if currently running
            if h.dirtySession && h.sessionService.hasSubject()
                h.endSession();
            end
            
            if h.dirtySession || ~h.sessionService.hasSubject()
                if ~h.openSession()
                    error('PolarionAdapter:OpenSessionError', ...
                        ['Could not open session. Please check your credentials '...
                        'and network connection.']);
                end
                h.dirtySession = false;
            end
        end
        
        % -----------------------------------------------------------------
        
        % Returns query http requests
        function s = getQueryRestRequest(h, queryString)
            s = [h.sServerURL '/#/project/' h.sProjectID '/workitems?query='...
                strrep(queryString, ' ', '%20')];
        end
        
        % -----------------------------------------------------------------
        
        function ids = id2uri(h, ids)
            noUri = ~h.isUri(ids);
            if iscell(ids)
                ids(noUri) = ...
                    cellstr(string('subterra:data-service:objects:/default/') + h.sProjectID + '${WorkItem}' + ids(noUri));
            else
                if noUri
                    ids = char(string('subterra:data-service:objects:/default/') + h.sProjectID + '${WorkItem}' + ids);
                end
            end
        end
        
        % -----------------------------------------------------------------
        
        function ids = uri2id(~, ids)
            ids = regexp(ids, '(?<=[?&]id=).*?(?=&|$)', 'match');
            assert(all(cellfun(@isscalar, ids)));
            ids = [ids{:}];
        end
        
        % -----------------------------------------------------------------
        
        function b = isUri(~, ids)
            b = startsWith(string(ids), 'subterra:data-service:objects:');
        end
        
        % -----------------------------------------------------------------        
        
        function b = isLinkApplicable(~, ~)
            % isLinkApplicable Returns true if the link matches the
            % Polarion format. No predonditions here, so always returns
            % true.
            b = true;
        end
        
        % -----------------------------------------------------------------
        
        % See base class
        function itemId = resolveLink(h, linkDestAddress)
            if h.cachedItems.isKey(linkDestAddress)
                itemId = linkDestAddress;
            else
                itemId = "";
            end
        end
        
        % -----------------------------------------------------------------
        
        % See base class
        function b = isLinkSuspected(h, rmiLinkPropertyTable)
            b = h.mgr.getSuspicionModel().isLinkSuspected(rmiLinkPropertyTable,'Polarion');
        end
        
        % -----------------------------------------------------------------
        
        function s = getServiceURL(h)
            s = [h.sServerURL '/ws/services/'];
        end
        
        % -----------------------------------------------------------------
        
        function b = openSession(h)
            h.notifyStatus("Opening session...");
            try
                % Priority:
                % 1 - Locally safed credentials
                % 2 - Credentials in preferences
                % 3 - Ask for credentials
                
                hasLocalUserName = ~isempty(h.sUserName);
                hasLocalUserPassword = ~isempty(h.sUserPassword);
                
                hasPrefUserName = ispref('SimPol', 'UserName') &&...
                    ~isempty(getpref('SimPol', 'UserName'));
                
                % Legacy cleanup - we do not store the password anymore
                if ispref('SimPol', 'UserPassword')
                    rmpref('SimPol', 'UserPassword');
                end
                
                % Choose username
                if hasLocalUserName
                    username = h.sUserName;
                elseif hasPrefUserName
                    username = getpref('SimPol', 'UserName');
                else
                    username = '';
                end
                
                % Choose password
                if hasLocalUserPassword
                    password = h.sUserPassword;
                else
                    if isempty(username)
                        [password, username] = passwordEntryDialog(...
                            'enterUserName', true, 'CheckPasswordLength', false);
                        
                        if password ~= -1 % Dialog canceled
                            password = simpol.utils.Utils.encrypt(password);
                            h.sUserName = username;
                            h.sUserPassword = password;
                        end
                        
                    else
                        password =  passwordEntryDialog(...
                            'CheckPasswordLength', false);
                        
                        if password ~= -1
                            password = simpol.utils.Utils.encrypt(password);
                            h.sUserPassword = password;
                        end
                    end
                end
                
                if isempty(username) || isempty(password)
                    b = false;
                else
                   % Open session
                    h.sessionService.logIn(username, h.decrypt(password));
                    b = h.sessionService.hasSubject();   
                end
                
            catch ME
                h.notifyStatus("Login failed. Please check your " + ...
                    "credentials and server URL.");
                b = false;
            end
            
            % Delete stored credentials in case of a failed authorization
            if ~b
                h.sUserName = '';
                h.sUserPassword = [];                
            end

        end        
        
    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods(Access=private)
        
        function item = createItem(h, jWorkItem)
            % createItem Copies the relevent information from a java
            % polarion work item. Returns simpol.data.Item.
            
            item = simpol.data.Item();
            item.id = char(jWorkItem.getId());
            item.optional('uri') = char(jWorkItem.getUri());
            item.name = [char(jWorkItem.getId()) ' - ' char(jWorkItem.getTitle())];
            if ~isempty(jWorkItem.getDescription()) && ~isempty(h)
                    
                s = char(jWorkItem.getDescription().getContent());
                doc = simpol.utils.XML.str2dom(s, 'fragment', true); % Parse fragment
            
                nl = h.getImageTags(doc);
                for i = 1:nl.getLength()
                    doc.getFirstChild().removeChild(nl.item(i-1));
                end

                item.description = simpol.utils.XML.dom2str(doc, 'fragment', true);           
            end
            if ~isempty(jWorkItem.getUpdated())
                item.lastUpdated = num2str(jWorkItem.getUpdated().getTimeInMillis());
            end
            
            % Get hierarchy by investigated the linked work items for valid
            % parents and check for suspicion
            % -------------------------------------------------------------
            jLinkedItems = jWorkItem.getLinkedWorkItems();
            
            if ~isempty(jLinkedItems)
                parentIds = strings(numel(jLinkedItems), 1);

                for i = 1:numel(jLinkedItems)
                     
                    % Get suspicion
                    item.suspected = item.suspected | ...
                        logical(jLinkedItems(i).getSuspect() == java.lang.Boolean(true));
                    
                    % If the link role is set and th link resembles the
                    % link rol, add a parent.
                    if ~isempty(h.settings.HierarchyLinkRoles) &&...
                            any(strcmp(...
                                char(jLinkedItems(i).getRole().getId()),...
                                h.settings.HierarchyLinkRoles...
                            ))
                        parentIds(i) = char(jLinkedItems(i).getWorkItemURI());
                    end
                    
                end
                
                % The parent ID is the uri
                parentIds = erase(parentIds, ...
                    "subterra:data-service:objects:/default/" + h.sProjectID + "${WorkItem}");
                item.parentWorkItemIds = cellstr(parentIds); 
            end
        end        
        
        function endSession(h)
            if ~isempty(h.sessionService)
                h.notifyStatus("Closing session...");
                % Close session. If it was not valid, this will throw an
                % error.
                try
                    h.sessionService.endSession();
                catch
                end
                h.notifyStatus("Session closed.");
            end
        end
        
        % -----------------------------------------------------------------
        
        function password = decrypt(h, i8_hash)

            c = clock;
            
            mgr = SimPol('instance');
            
            u8_key = uint8([112    c(1:3) 121  125   114 ...
                (typecast(double(mgr.hSimPolGUI.UIFigure), 'uint8') +...
                uint8([165   181   193    70   174   167    41    30]))   127]);
            sks = javax.crypto.spec.SecretKeySpec(u8_key , 'AES');
            cipher = javax.crypto.Cipher.getInstance('AES/ECB/PKCS5Padding', 'SunJCE');
            cipher.init(javax.crypto.Cipher.DECRYPT_MODE, sks);
            password = char(cipher.doFinal(i8_hash))';
        end
    end
    
end

