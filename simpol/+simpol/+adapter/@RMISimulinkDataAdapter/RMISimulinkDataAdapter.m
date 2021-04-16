classdef RMISimulinkDataAdapter < simpol.adapter.AbstractBasicRMIAdapter
    
    % There are three different IDs.
    % Targets are always stored as file name without extension.
    % Sectionless ID: target|item-name
    % Normal ID: target|Design.item-name
    
    %% --------------------------------------------------------------------
    % METHODS
    % ---------------------------------------------------------------------
    methods
        function h = RMISimulinkDataAdapter(mgr)
            h = h@simpol.adapter.AbstractBasicRMIAdapter(mgr);
        end
        
        % Overwrite addLink
        function b = addLinkImpl(h, itemId, newLinkId, data)
            h.ensureIsWritable();
            % Before 2017b, Design. prefix is required to identify item as
            % part of the Design Data section.
            if verLessThan('matlab', '9.3')
                data.rmiItemId = itemId;
            else
                data.rmiItemId = h.sectionlessId(itemId);
                
            end
            b = defaultAddLink(h, ...
                itemId, newLinkId, data);
        end    
        
        % Externall defined 
        item = createItem(h, itemId); 
        itemIds = findItemIdsToCache(h)
        
        % -----------------------------------------------------------------
        
        function b = removeLinkImpl(h, link)
            b = h.defaultRemoveLink(link);
        end       
        
         % -----------------------------------------------------------------
        
        function updateCachedItemImpl(h, itemId)
             h.defaultUpdateCachedItem(itemId);
        end       
        
        % See base class
        function url = getNavURL(h, itemId)
            % Get url of block
            [ddname, entryname] = h.splitId(itemId);
            url = ['http://localhost:' num2str(connector.port) ...
                '/matlab/feval/rmiobjnavigate?arguments=%5b%22' ...
                ddname '%22,%22Design.' entryname '%22%5d'];
        end
        

        function b = isLinkApplicable(~, link)
            % isLinkApplicable Checks if a rmi hyperlink is applicable for 
            % this kind of RMI adapter type.           
            b = contains(link.toItemId, 'rmiobjnavigate') && ...
                contains(link.toItemId, '.sldd%22');
        end    
        
        % See base class
        function loadTargetForIds(h, itemIds)
            
            if isempty(itemIds)
                return;
            end
            
            ddNames = unique(strtok(itemIds, ':'));
            
            try
                for i = 1:numel(ddNames)
                    Simulink.data.dictionary.open([ddNames '.sldd']);
                end
            catch
            end
        end
        
        % See base class
        function show(h, itemId)
            try
                [ddname, entryname] = h.splitId(itemId);
                rmiobjnavigate(ddname, ['Design.' entryname]);
            catch
                warning('Cannot hilight system.');
            end
        end
    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods(Static)
        
        function b = supportsSnapshot()
            % supportsSnapshot Simulink data adapter does not support
            % making a snapshot.
            b = false;
        end
        
        % -----------------------------------------------------------------

        function makeSnapshot(~, ~)
            % makeSnapshot Stubbed function.
            assert(false, "Snap shots are not supported.");
        end 
        
        % -----------------------------------------------------------------
        
        % See base class
        function targets = detectTargets(h)
            ddpaths = Simulink.data.dictionary.getOpenDictionaryPaths();
            
            targets = [];
            for i = 1:numel(ddpaths)
                [~, targets{end+1}] = fileparts(ddpaths{i});
            end
        end
        
        % See base class
        function fileFilter = getTargetFileFilter()
            fileFilter = {'.sldd'};
        end
        
        
        function  target = validateTarget(targetFilePath)
            [~,target, ext] = fileparts(targetFilePath);
            
            if ~any(strcmp(ext, simpol.adapter.RMISimulinkDataAdapter.getTargetFileFilter()))
                target = {};
            end
        end
        
        function b = isTargetAvailable(target)
            try
                simpol.adapter.RMISimulinkDataAdapter.loadTarget([target '.sldd']);
                b = true;
            catch
                b = false;
            end
        end
        
        function loadTarget(target)
            Simulink.data.dictionary.open(target);
        end
        
        function name = getName()
            name = 'Simulink Data';
        end
        
        function iconFileName = getItemIcon(~)
            iconFileName = 'simpol_ddentry.png';
        end              
        
        function id = getIDFromURL(url)
            matches = regexp(url, '%22.*?%22', 'match');
            
            if numel(matches) ~= 2
                id = url;
            else
                dd = matches{1};
                ddname = dd(4:end-3);
                
                ename = matches{2};
                ename = ename(4:end-3);
                ename = reverse(strtok(reverse(ename), '.'));
                
                id = simpol.adapter.RMISimulinkDataAdapter.toItemId(ddname, ename);
            end
        end
        
        % See base class
        function b = providesSelection()
            b = false;
        end   
        
        % See base class
        function items = getSelectedItems(targets)
            items = [];
        end      
        
    end
    
    methods(Static)
        
        function [ddname, entryname] = splitId(itemId)
                ddname = strtok(itemId, '|');
                entryname = char(extractAfter(itemId, '|Design.'));            
        end
        
        function id = sectionlessId(ddname_or_itemId, entryname)
            
            if nargin == 2
                itemId = simpol.adapter.RMISimulinkDataAdapter.toItemId(ddname_or_itemId, entryname);
            else
                itemId = ddname_or_itemId;
            end
            
            id = char(erase(itemId, 'Design.'));
            
        end
        
        function itemId = toItemId(ddname, entryname)
            
            itemId = [ddname '|Design.' entryname];
                
        end
    end
    
end
