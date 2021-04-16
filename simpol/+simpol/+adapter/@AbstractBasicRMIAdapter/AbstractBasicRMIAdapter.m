classdef AbstractBasicRMIAdapter < simpol.adapter.AbstractAdapter
    % AbstractBasicRMIAdapter provides shared implementations of abstract
    % functions for further concrete adapters, that work with the RMI
    % interface.
    % Unique is also the tracker functionality, which allows to track the
    % selection of RMI elements in other tools, e.g., Simulink. This can be
    % used for in-tool linking workflows.
    
    properties(GetAccess=public, SetAccess=protected)
        % Name of the selected tracker
        trackerName = '';
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods(Abstract)  
        % Additional abstract methods of the RMI Adapter
        
        % Composes a RMI URL
        url = getNavURL(h, itemId);
        
        % Creates a new internal data item from a given ID.
        item = createItem(h, itemId);
        
        % Adds a link to the item with itemId. newLinkId is the ID of the
        % new link, data is a custom data struct.
        b = addLinkImpl(h, itemId, newLinkId, data);        
        
        % Removes a link. Returns true if successful. Link is of type
        % simpol.data.Link
        b = removeLinkImpl(h, link);
        
        % This method returns ids of all items that shall be cached. This
        % typically depends on the targets. Returns [] or a cell array of
        % IDs.        
        itemIds = findItemIdsToCache(h);       
    end
        
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods(Abstract, Static)    
        
        % Returns true, if the adapter supports creating a snapshot of
        % items, otherwise false. 
        b = supportsSnapshot();
        
        % Creates a snapshot of the item (if supported)
        imgPath = makeSnapshot(mItemId);
        
        % Extracts an ID from a RMI url.
        id = getIDFromURL(url)
        
        % This method shall detect "open" target files.
        % The result must be written as cell array into targetFilePaths
        % property.
        targets = detectTargets();
        
        % Returns target file filter
        fileFilter = getTargetFileFilter();
        
        % Validate target. Throws an error, if the target is not valid
        target = validateTarget(targetFilePath);
        
        % Check if target is available
        b = isTargetAvailable(target);

        % Load the target
        loadTarget(target);
        
        % Indicates whether the selection can be obtained from the target
        b = providesSelection();
        
        % Get selected items if supported
        items = getSelectedItems(targets);
        
    end
       
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods

        function h = AbstractBasicRMIAdapter(mgr)
            h = h@simpol.adapter.AbstractAdapter(mgr);
        end
        
        % -----------------------------------------------------------------
        
        function b = addLink(h, itemId, newLinkId, data)
            % addLink Wrapper to make sure that event is fired.
            b = h.addLinkImpl(itemId, newLinkId, data);
            if b
                h.notify("ItemCacheChangedEvent");
            end
        end
        
        % -----------------------------------------------------------------
        
        function b = removeLink(h, link)
            % removeLink Wrapper to make sure that event is fired.
             b = removeLinkImpl(h, link);
             if b
                h.notify("ItemCacheChangedEvent");
             end
        end
        
        % -----------------------------------------------------------------
        
        % Sets the currently active tracker
        function setTracker(h, trackerName)
            assert(any(strcmp(h.getTrackerNames, trackerName)));
            h.trackerName = trackerName;
        end 
        
        % -----------------------------------------------------------------
        
        % Relodas all cached items.
        function updateCacheImpl(h)
            
            % Clear cache
            if h.cachedItems.Count > 0
                h.cachedItems.remove(h.cachedItems.keys());
            end
            
            % Update block paths
            ids = h.findItemIdsToCache();
            
              if ispref('SimPol', 'ItemCacheLimit')
                limit = getpref('SimPol', 'ItemCacheLimit');
              else
                limit = 4000;
              end

              if numel(ids) > limit
                  warning(['Number of cached items exceeds the specified limit of '...
                      num2str(limit) ' items. Set preference ''RMICacheLimit'' to a higher limit, '...
                      'reduce target size or the number of loaded targets.']);
                  ids = ids(1:limit);
              end            
            
            % Update cache for each block path
            for i = 1:numel(ids)
                if iscell(ids)
                    h.updateCachedItem(ids{i});
                else
                    h.updateCachedItem(ids(i));
                end
            end

        end
        
        % -----------------------------------------------------------------
        
        function defaultUpdateCachedItem(h, itemId)
            % defaultUpdateCachedItem 
            % A generic implementation of updateCachedItem, which can be
            % called by subclasses.
            % We cannot overrride multiple times in MATLAB like C++.
            
            item = h.createItem(itemId);

            rmiLinks = rmi('get', itemId);
            links = simpol.data.Link.empty(0, numel(rmiLinks));
            for i = 1:numel(rmiLinks)
                links(i) = h.createLinkFromRMIStruct(item, rmiLinks(i), i);
            end
            item.links = links;

            h.cachedItems(itemId) = item;
        end
        
        % -----------------------------------------------------------------
        
        function b = isLinkApplicable(~, ~)
            % isLinkApplicable Returns true if the link is applicable. The
            % RMI adapter as no preconditions on the link information and
            % thus always returns true.
            b = true;
        end
        
        % -----------------------------------------------------------------
        
        % See base class
        function itemId = resolveLink(h, linkDestAddress)
            itemId = h.getIDFromURL(linkDestAddress);
            if h.cachedItems.isKey(itemId)
                itemId = string(itemId);
            else
                itemId = "";
            end
        end
        
        % -----------------------------------------------------------------
                
        % See base class
        function b = isLinkSuspected(h, polarionLinkPropertyTable)
            b = h.mgr.getSuspicionModel().isLinkSuspected(polarionLinkPropertyTable,'RMI');
        end   
        
        % -----------------------------------------------------------------
        
        % RMI adapters do not have a read-only state at the moment.
        function b = isReadOnly(h)
           b = false;
        end
        
        % -----------------------------------------------------------------
        
        function b = defaultAddLink(h, itemId, newLinkId, data)
            
            h.ensureIsWritable();
            
            % Data must contain
            % - doc (polarion server url)
            % - description (raw id of of requirement)
            % - id (relative url of requirement on server)
            % - rmiItemId (ID used by rmi to find items)
            
            itemId = char(itemId);
            
            % Do nothing if link already exists
            existingLinks = rmi('get', char(data.rmiItemId));
            if ~isempty(existingLinks) && any(strcmp({existingLinks.id}, char(data.id)))
                b = true;
                return;
            end
            
            rl = rmi('createEmpty');
            rl.doc = char(data.doc);
            rl.description = char(data.description);
            rl.id = char(data.id);
            rl.keywords = char(strjoin(["uptraceRevision", string(data.revision)], ","));
            rl.reqsys = 'linktype_polarion';
            
            rmi('cat', char(data.rmiItemId), rl);
            
            h.updateCachedItem(itemId);
            
            b = true;
            
        end
        
        % -----------------------------------------------------------------
        
        function b = defaultRemoveLink(h, link)
            % defaultRemoveLink Default implementation for removing an RMI
            % link.
            
            b = false;
            
            h.ensureIsWritable();
            
            try
                links = rmi('get', char(link.itemId));
            catch
                 return;
            end
            
            % RMI IDs are always stored in the format sid|index
            splits = strsplit(link.id, "|");
            if numel(splits) < 2
                return;
            end
            
            bKeep = true(numel(links), 1);
            bKeep(str2double(splits(end))) = false;
            links = links(bKeep);
            
            rmi('set', link.itemId, links);
            
            h.updateCachedItem(link.itemId);
            
            b = true;
        end
    end
    
    methods(Static)
     
        % -----------------------------------------------------------------
        
        function side = getSide()
            side = simpol.SideType.MATLAB;
        end       
        
        % -----------------------------------------------------------------
     
        function link = createLinkFromRMIStruct(item, rmiLink, idx)
                parser = simpol.utils.PolarionURLParser(rmiLink.id);
                
                link = simpol.data.Link(item, string(idx));    
                link.fromSide = simpol.SideType.MATLAB;
                link.toItemId = string(parser.getWorkItemId());
                link.unresolvedName = strrep(rmiLink.description, 'Polarion: ', '');
                
                % Extract keywords key-value pairs
                if ~isempty(rmiLink.keywords)
                    
                    % Since before a semincolon was used.... set suspected
                    % to get the force the new format
                    if isempty(strfind(rmiLink.keywords, 'uptraceChecksum;'))...
                            && ~isempty(strfind(rmiLink.keywords, 'uptraceRevision'))
                        p = inputParser;
                        p.KeepUnmatched = true;
                        p.addParameter('uptraceRevision', '');
                        params = strsplit(rmiLink.keywords, ',');
                        p.parse(params{:});
                        link.toRevision = p.Results.uptraceRevision;
                    end
                end            
        end
    end    
end
