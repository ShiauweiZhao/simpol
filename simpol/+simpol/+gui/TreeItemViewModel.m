classdef TreeItemViewModel < simpol.gui.AbstractItemViewModel
    
    properties
        % Stores a map with [item-id] => cell array of nodes
        mapNodes;
        % Stores a map with item IDs of dirty items (value is true for all)
        mapDirtyItemIDs;
        % Expanded node IDs
        mapExpandedItemIDs;
        % True if display is flat
        flatDisplay = false;
        % Digraph behind
        dg;
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods
        function h = TreeItemViewModel(adapter, linkTable, uiElement)
            
            % Call super class
            h@simpol.gui.AbstractItemViewModel(adapter, linkTable, uiElement);
            
            % Initialize maps
            h.mapNodes = containers.Map;
            h.mapDirtyItemIDs = containers.Map;
            h.mapExpandedItemIDs = containers.Map;
                        
            % Set node expand/collapse callbacks
            uiElement.NodeExpandedFcn = @(app, event) h.itemNodeExpanded(app, event);
            uiElement.NodeCollapsedFcn = @(app, event) h.itemNodeCollapsed(app, event);
            
        end
        
        % -----------------------------------------------------------------
        
        function selectionChanged(h, event)
            
            node = event.SelectedNodes.NodeData;
            
            if strcmp(node{1}, 'item')
                h.selectedItemId = convertCharsToStrings(node{3});
                h.selectedItemIdx = node{2};
                h.selectedLinkId = strings(0);
                h.selectedLinkIdx = 0;
                h.itemSelected = true;
                h.linkSelected = false;
            elseif strcmp(node{1}, 'link')
                h.selectedItemId = strings(0);
                h.selectedItemIdx = 0;
                h.selectedLinkId =  convertCharsToStrings(node{3});
                h.selectedLinkIdx = convertCharsToStrings(node{2});
                h.itemSelected = false;
                h.linkSelected = true;
            else
                error("Unkown node type: " + node{1});
            end
        end
        
        % -----------------------------------------------------------------
        
        function itemNodeCollapsed(h, app, event)
            itemId = h.getItemId(event.Node);
            if ~isempty(itemId) && h.mapExpandedItemIDs.isKey(itemId)
                h.mapExpandedItemIDs.remove(itemId);
            end
        end
        
        % -----------------------------------------------------------------
        
        function itemNodeExpanded(h, app, event)
            itemId = h.getItemId(event.Node);
            if ~isempty(itemId)
                h.populateNodeGrandChildren(event.Node);
                h.mapExpandedItemIDs(itemId) = true;
            end
        end
        
        % -----------------------------------------------------------------
        
        function updateViewModelImpl(h)
            
            if ~isempty(h.adapter)
                
                ids = convertStringsToChars(h.itemFilter.exec(h.adapter, h.linkTable));
                
                % Get trace graph... this graph contains the interrelations
                % of items
                itemsUnchanged = ~isempty(h.dg) && (h.mapNodes.Count > 0) && (numel(ids) == h.mapNodes.Count) && (numel(intersect(h.mapNodes.keys, ids)) == numel(ids));
                h.dg = h.getTraceGraph(h.adapter.getCachedItems(ids));
                
                changedDisplay=(numel(ids) ~= h.dg.numnodes());
                h.flatDisplay=false;
                if numel(ids)==1
                    h.flatDisplay=true;
                end
                % From every root node, traverse tree
                if ~changedDisplay && ~isempty(h.mapNodes) && itemsUnchanged
                    % Existing
                    dirtyKeys = h.mapDirtyItemIDs.keys();
                    dirtyItemIDs = dirtyKeys(h.mapNodes.isKey(h.mapDirtyItemIDs.keys));
                    
                    for i = 1:numel(dirtyItemIDs)
                        nodes = h.mapNodes(dirtyItemIDs{i});
                        for j = 1:numel(nodes)
                            h.updateLinkNodes(nodes{j});
                           
                        end
                    end
                    
                    h.mapDirtyItemIDs = containers.Map;
                    
                elseif ~h.flatDisplay
                    
                    
                    h.clearUI();
                    h.mapNodes = containers.Map;
                    h.mapDirtyItemIDs = containers.Map;
                    
                    if h.dg.numnodes > 0
                        
                        if ~h.dg.isdag()
                            
                            h.notifyWarn(...
                                "The requirement graph generated from loaded " + ...
                                "Polarion requirements is cyclic. " + newline +...
                                "SimPol can not determine root nodes and will not " + ...
                                "display all requirements.");
                            
                            % Plot trace tree
                            hFigure =  figure;
                            hPlot = plot(h.dg);
                            set(findobj(gcf, 'type','axes'), 'Visible','off');
                            set(hFigure, 'MenuBar', 'none');
                            set(hFigure, 'ToolBar', 'none');
                            set(hFigure, 'Color', 'w');
                        end
                        
                        rootIndices = getRoots(h, h.dg);
                        rootIds = h.dg.Nodes.Name(rootIndices);
                        for iRoot = 1:numel(rootIndices)
                            h.createNode([], rootIds{iRoot}, 0);
                        end
                        h.populateNodeGrandChildren(h.uiElement);
                    end
                    
                    % Delete nodes
                    nodesToDelete = setdiff(h.mapNodes.keys, ids);
                    for i = 1:numel(nodesToDelete)
                        cellfun(@(x) delete(x), h.mapNodes(nodesToDelete{i}));
                    end
                    h.mapNodes.remove(nodesToDelete);
                    h.mapDirtyItemIDs.remove(intersect(h.mapDirtyItemIDs.keys,nodesToDelete));
                    h.mapExpandedItemIDs.remove(intersect(h.mapExpandedItemIDs.keys,nodesToDelete));
                    
                    pause(.1); % Doesn't expand correctly otherwise...
                    
                    % Remember expansion state
                    expandIDs = h.mapExpandedItemIDs.keys();
                    for i = 1:numel(expandIDs)
                        if h.mapNodes.isKey(expandIDs{i})
                            nodes = h.mapNodes(expandIDs{i});
                            for j = 1:numel(nodes)
                                expand(nodes{j});
                                event.Node = nodes{j};
                                h.itemNodeExpanded([], event);
                            end
                        else
                            h.mapExpandedItemIDs.remove(expandIDs{i});
                        end
                    end
                    
                else
                    % Delete nodes
                    h.clearUI();
                    h.mapNodes = containers.Map;
                    nodesToDelete = setdiff(sstringh.mapNodes.keys, ids);
                    for i = 1:numel(nodesToDelete)
                        cellfun(@(x) delete(x), h.mapNodes(nodesToDelete{i}));
                    end
                    h.mapNodes.remove(nodesToDelete);
                    h.mapDirtyItemIDs.remove(intersect(h.mapDirtyItemIDs.keys,nodesToDelete));
                    h.mapExpandedItemIDs.remove(intersect(h.mapExpandedItemIDs.keys,nodesToDelete));
                    

                % Add nodes
                    nodesToAdd = ids;
                    for i = 1:numel(nodesToAdd)

                        h.createNode([], nodesToAdd{i}, 0);

                        % Sort if we are in flat mode
                        newNode = h.mapNodes(nodesToAdd{i});

                        % Since a map already sorts, find node under keys
                        % and get the index of the next element.
                        % Move the node before the next element.
                        keys = h.mapNodes.keys();
                        idx = find(strcmp(keys, nodesToAdd{i}), 1, 'first')+1;
                        if idx < h.mapNodes.Count
                            beforeNode = h.mapNodes(keys{idx});
                            move(newNode{1}, beforeNode{1}, 'before');
                        end


                    if h.mapNodes.Count > 100
                        h.notifyWarn(...
                            "The maximum number of displayable nodes " + ...
                            "(100 due to performance reasons) has been reached." + ...
                            "Please detail your filter criteria or use smaller " + ...
                            "models to show all nodes.");
                        break;
                    end

                    end
                    
                    h.populateNodeGrandChildren(h.uiElement);
                end
                                
            end
            
            % If there is one node, directly select it
            if h.getNumItems() == 1
                h.uiElement.SelectedNodes = h.uiElement.Children;
                fakeEvent.SelectedNodes = h.uiElement.SelectedNodes;
                h.uiElement.SelectionChangedFcn([], fakeEvent);
            end      
            
        end
        
        % -----------------------------------------------------------------
        
        function n = getNumItems(h)
            n = h.mapNodes.Count;
        end
        
        % -----------------------------------------------------------------
        
        function clearSelection(h)
            h.selectedItemId = [];
            h.selectedLinkId = [];
            h.selectedLinkIdx = [];
            h.selectedItemIdx = [];
            h.itemSelected = false;
            h.linkSelected = false;
        end
                
        % -----------------------------------------------------------------
        
        function dirtyItem(h, itemId)
            if ~h.mapDirtyItemIDs.isKey(itemId)
                h.mapDirtyItemIDs(itemId) = true;
            end
        end
        
        % -----------------------------------------------------------------
        
        function dirtyAll(h)
            if h.mapNodes.Count > 0
                h.mapDirtyItemIDs = containers.Map(h.mapNodes.keys(),...
                    ones(1, h.mapNodes.Count, 'logical'));
            end
        end
    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods(Access=private)
        
        function createNode(h, parentNode, itemId, itemIdx)

            item = h.adapter.getCachedItem(itemId);
            name = item.name;
            
            if ~isempty(h.linkTable) && isvalid(h.linkTable)
                links = h.linkTable.getLinksOfItem(h.adapter.getSide(), itemId);
            else
                links = [];
            end
            
            if isempty(parentNode)
                parentNode = h.uiElement;
            end
            
            
            % Create item node
            itemIconFileName = h.adapter.getItemIcon(item);
            
            itemNode = uitreenode(parentNode,...
                'Text', h.getItemNodeText(name, numel(links)),...
                'Icon', itemIconFileName,...
                'NodeData', {'item', itemIdx, itemId});
            
            if ~h.mapNodes.isKey(itemId)
                h.mapNodes(itemId) = {itemNode};
            else
                existingNodes = {itemNode};
                tmp=h.mapNodes(itemId);
                existingNodes{end+1} = tmp{:};
                h.mapNodes(itemId) = existingNodes;
            end
            
        end
        
        % -----------------------------------------------------------------
        
        function clearUI(h)
            ch = h.uiElement.Children;
            set(ch, 'Parent', []);
            delete(ch);
        end
        
        % -----------------------------------------------------------------
        
        function populateNodeChildren(h, parentItemNode)
            itemId = parentItemNode.NodeData{3};
            
            if numel(parentItemNode.Children) == 0
                if ~h.flatDisplay
                    childItemIDs = h.dg.successors(itemId);
                    for i = 1:numel(childItemIDs)
                        h.createNode(parentItemNode, childItemIDs{i}, 0)
                    end
                end
                h.updateLinkNodes(parentItemNode);
            end
        end
        
        % -----------------------------------------------------------------
        
        function populateNodeGrandChildren(h, parentItemNode)
            for iChild = 1:numel(parentItemNode.Children)
                childNode = parentItemNode.Children(iChild);
                if strcmp(childNode.NodeData{1}, 'item')
                    h.populateNodeChildren(childNode);
                end
            end
        end
        
        % -----------------------------------------------------------------
        
        function updateLinkNodes(h, parentItemNode)
            
            itemId = parentItemNode.NodeData{3};
            item = h.adapter.getCachedItem(itemId);
            
            if ~isempty(h.linkFilter)
                [links, linkProperties] = h.linkFilter.exec(...
                    h.adapter.getSide(), string(itemId), h.linkTable);
            else
                [links, linkProperties] = h.linkTable.getLinksOfItem(...
                    h.adapter.getSide(), string(itemId));
            end
            
            % Set new text for parentItemNode
            parentItemNode.Text = h.getItemNodeText(item.name, numel(links));
            
            % Remove all link children
            nodesToDelete = [];
            for iChild = 1:numel(parentItemNode.Children)
                if h.isLinkNode(parentItemNode.Children(iChild))
                    nodesToDelete = [nodesToDelete parentItemNode.Children(iChild)]; %#ok<AGROW>
                end
            end
            
            set(nodesToDelete, 'Parent', []);
            delete(nodesToDelete);
            
            % Create links
            for j = 1:size(linkProperties,1)
                
                name = linkProperties.DisplayName(j);
                if ~linkProperties.Resolvable(j)
                    icon = 'simpol_link_unresolvable';
                elseif ~linkProperties.BiDirectional(j)
                    icon = 'simpol_link_broken';
                else
                    icon = 'simpol_link_ok';
                end
                if linkProperties.Suspected(j)
                    icon = [icon '_suspected']; %#ok<AGROW>
                end
                
                icon = [icon '.png']; %#ok<AGROW>
                
                if isempty(strtrim(name))
                    name = '<unnamed>';
                end
                
                uitreenode(parentItemNode,...
                    'Text', name,...
                    'Icon', icon,...
                    'NodeData', {'link', j, linkProperties.Link(j).id});
            end
            
            
        end
        
        % -----------------------------------------------------------------

        function indices = getRoots(h, dg)
            % getRoots Returns indices of all root nodes.
            % h      Handle to class
            % dg     Directed graph
            % Returns indices of roots nodes.
            
            indices = [];
            
            if dg.numnodes > 0
                indices = find(~any(dg.adjacency,1));
            end
            
        end
        
        % -----------------------------------------------------------------
        
        function s = getItemNodeText(h, name, count)
            s = string(name) + " (" + count + ")";
        end
        
        % -----------------------------------------------------------------
        
        function b = isItemNode(h, node)
            b = strcmp(node.NodeData{1}, 'item');
        end
        
        % -----------------------------------------------------------------
        
        function b = isLinkNode(h, node)
            b = strcmp(node.NodeData{1}, 'link');
        end
        
        % -----------------------------------------------------------------
        
        function itemId = getItemId(h, node)
            if h.isItemNode(node)
                itemId = node.NodeData{3};
            else
                itemId = [];
            end
        end
        
        % -----------------------------------------------------------------
        
        function dg = getTraceGraph(~, cachedItems, normalized)    
        % getTraceGraph Helper to composes a directed graph out of the items.
        % Therefore, the property parentWorkItemIds is used.
        % cachedItems   Cached items from adapter
        % normalized    If normalized is set true, the tree is unfolded, so
        %               that every node just has a single parent. 
        % Returns a digraph object.
            
            dg = digraph;
            
            if isempty(cachedItems)
                return;
            end
            
            keys = cellfun(@(x) x.id, cachedItems);
            
            if isempty(keys)
                return;
            end
            
            % Add all nodes
            dg = dg.addnode(keys);
            
            e1 = strings(0);
            e2 = strings(0);
            
            for iItem = 1:numel(cachedItems)
                item = cachedItems{iItem};
                for iParent = 1:numel(item.parentWorkItemIds)
                    parentId = item.parentWorkItemIds(iParent);
                    
                    % Only add dependency, if the linked parent is in the
                    % queried set.
                    if any(strcmp(keys, parentId))
                        e1(end+1) = parentId;
                        e2(end+1) = item.id;
                    end
                end
            end
            dg = dg.addedge(e1, e2);
            
            % Normalize tree
            if nargin > 2 && normalized
                flag = true;
                while(flag)
                    dg.Nodes.Name(full(sum(dg.adjacency,1) > 1))
                end
            end 
        end
        
    end
    
end

