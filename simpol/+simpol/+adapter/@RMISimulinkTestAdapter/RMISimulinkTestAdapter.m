classdef RMISimulinkTestAdapter < simpol.adapter.AbstractBasicRMIAdapter
    
    %% --------------------------------------------------------------------
    % METHODS
    % ---------------------------------------------------------------------
    methods
        function h = RMISimulinkTestAdapter(mgr)
            h = h@simpol.adapter.AbstractBasicRMIAdapter(mgr);
        end
        
        function b = addLinkImpl(h, itemId, newLinkId, data)
            h.ensureIsWritable();
            data.rmiItemId = itemId;
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
            
            [name, uuid] = h.splitId(itemId);
            
            url = ['http://localhost:' num2str(connector.port) ...
                '/matlab/feval/rmitmnavigate?arguments=%5b%22' ...
                name '%22,%22' uuid '%22%5d'];
        end
        
        function b = isLinkApplicable(~, link)
            % isLinkApplicable Returns true if the link can be interpreted
            % by this adapter, i.e., the url matches a specific pattern.
            b = ~isempty(strfind(link.toItemId, 'rmitmnavigate')) && ...
                ~isempty(strfind(link.toItemId, '.mldatx%22'));
        end
        
        % See base class
        function loadTargetForIds(h, itemIds)
            
            if isempty(itemIds)
                return;
            end
            
            tfnames = unique(strtok(itemIds, '|'));
            
            for i = 1:numel(tfnames)
                try
                    files = which(tfnames{i});
                    if iscell(files) && numel(files) > 1
                        h.notifyWarn("Shadowed file for model " + tfnames{i});
                        continue;
                    end
                    sltest.testmanager.load(tfnames{i});
                catch
                end
            end
        end
        
        % See base class
        function show(h, itemId)
            [name, uuid] = h.splitId(itemId);
            rmitmnavigate(name, uuid);
        end
    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods(Static)
        
        function b = supportsSnapshot()
            % supportsSnapshot Simulink test adapter does not support
            % making a snapshot.
            b = false;
        end
        
        % -----------------------------------------------------------------
        
        function makeSnapshot(~, ~)
            % makeSnapshot Stubbed function.
            assert(false, "Snap shots are not supported.");
        end
        
        % -----------------------------------------------------------------
        
        function [target, uuid] = splitId(itemId)
            splits = strsplit(itemId, '|');
            
            target = splits{1};
            uuid = splits{2};
        end
        
        function itemId = makeItemId(target, uuid)
            [~, name, ext] = fileparts(target);
            itemId = [name ext '|' uuid];
        end
        
        % Detects alls open test files
        % See base class
        function targets = detectTargets()
            tfs = sltest.testmanager.getTestFiles();
            targets = {tfs.Name};
        end
        
        
        % See base class
        function fileFilter = getTargetFileFilter()
            fileFilter = {'.mldatx'};
        end
        
        function  target = validateTarget(targetFilePath)
            [~,target, ext] = fileparts(targetFilePath);
            
            if ~any(strcmp(ext, simpol.adapter.RMISimulinkTestAdapter.getTargetFileFilter()))
                target = {};
            end
        end
        
        function b = isTargetAvailable(target)
            try
                simpol.adapter.RMISimulinkTestAdapter.loadTarget(target);
                b = true;
            catch
                b = false;
            end
        end
        
        function loadTarget(target)
            sltest.testmanager.load(target);
        end
        
        
        function name = getName()
            name = 'Simulink Test';
        end
        
        function iconFileName = getItemIcon(~)
            iconFileName = 'simpol_test.png';
        end       
        
        % See base class
        function id = getIDFromURL(url)
            
            splits =  regexp(url, '%22.*?%22', 'match');
            
            if numel(splits) ~= 2
                id = url;
                return;
            end
            
            target = string(splits{1});
            target = target.erase('%22');
            
            uuid = string(splits{2});
            uuid = uuid.erase('%22');
            
            
            id = simpol.adapter.RMISimulinkTestAdapter.makeItemId(char(target), char(uuid));
            
        end
        
        % See base class
        function b = providesSelection()
            b = true;
        end
        
        % See base class
        function items = getSelectedItems(targets)
            items = [];
        end
        
    end
    
    methods(Access=private)
        
        function s = getTestObjectID(~, testfilename, to)
            % getTestObjID Creates the ID used with this adapter.
            % It is composed of the test file name and the UUID of the test
            % element.
            s = [testfilename '|' to.getProperty('uuid')];
        end

    end
    
end

