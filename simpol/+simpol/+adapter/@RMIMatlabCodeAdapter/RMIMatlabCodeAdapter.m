classdef RMIMatlabCodeAdapter < simpol.adapter.AbstractBasicRMIAdapter
    
    %% --------------------------------------------------------------------
    % METHODS
    % ---------------------------------------------------------------------
    methods
        function h = RMIMatlabCodeAdapter(mgr)
            h = h@simpol.adapter.AbstractBasicRMIAdapter(mgr);
        end
               
        % -----------------------------------------------------------------
        
        % Overwrite addLink
        function b = addLinkImpl(h, itemId, newLinkId, data)
            h.ensureIsWritable();
            
            [filename, rangeId] = h.splitId(itemId);
            
            data.rmiItemId = filename + "|" + rangeId;
            
            b = defaultAddLink(h, ...
                itemId, newLinkId, data);
        end
        
        % -----------------------------------------------------------------
        
        function b = removeLinkImpl(~, link)
            % removeLink MATLAB links cannot be removed, thus we cannot
            % use the default implementation
            
            res = questdlg(['SimPol can currently not remove '...
                'links in the MATLAB code (Not yet implemented). Use the RMI link editor to remove links.'],...
                'Remove link', 'Cancel', 'Remove manually', 'Cancel');
            
            if strcmp(res, 'Remove manually')
                rmiml.editLinks(link.itemId);
                b = true;
            else
                b = false;
            end
        end
        
         % -----------------------------------------------------------------
        
        function updateCachedItemImpl(h, itemId)
             h.defaultUpdateCachedItem(itemId);
        end        
    end
    
    methods
        
        % Externally defined 
        item = createItem(h, itemId); 
        itemIds = findItemIdsToCache(h);
        
        % See base class
        function url = getNavURL(h, itemId)
            % Get url of block
            [fileName, rangeId] = h.splitId(itemId);
            url = ['http://localhost:' num2str(connector.port) ...
                '/matlab/feval/rmicodenavigate?arguments=%5b%22' ...
                fileName '%22,%22' rangeId '%22%5d'];
        end
        
        function b = isLinkApplicable(~, link)
            % isLinkApplicable Checks if a rmi hyperlink is applicable 
            % for this kind of RMI adapter type.           
            b = contains(link.toItemId, 'rmicodenavigate');
        end
        
        % See base class
        function loadTargetForIds(h, itemIds)
            
            if isempty(itemIds)
                return;
            end
            
            fileNames = unique(strtok(itemIds, '|'));
            
            try
                for fileName = fileNames
                    edit(fileName);
                end
            catch
            end
        end
        
        % See base class
        function show(h, itemId)
            try
                [fileName, rangeId] = h.splitId(itemId);
                rmicodenavigate(fileName, rangeId);
            catch
                warning('Cannot hilight system.');
            end
        end
        
        
        
    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods(Static)
        
        function b = supportsSnapshot()
            % supportsSnapshot MATLAB code adapter does not support 
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
        function targets = detectTargets(~)
            
            % Undocumented MATLAB
            docs = matlab.desktop.editor.getAll;
            
            targets = [];
            for i = 1:numel(docs)
                if ~isempty(docs(i).Filename)
                    [~, targets{end+1}] = fileparts(docs(i).Filename);
                end
            end
        end
        
        % See base class
        function fileFilter = getTargetFileFilter()
            fileFilter = {'.m';'.slx'};
        end
        
        
        function  target = validateTarget(targetFilePath)
            [~,target, ext] = fileparts(targetFilePath);
            
            if ~any(strcmp(ext, simpol.adapter.RMIMatlabCodeAdapter.getTargetFileFilter()))
                target = {};
            end
        end
        
        function b = isTargetAvailable(target)
            b = ~isempty(which(target));
        end
        
        function loadTarget(target) %TBD
            open(target);
        end
        
        function name = getName()
            name = 'MATLAB Code';
        end
        
        function iconFileName = getItemIcon(~)
            iconFileName = 'simpol_mcode.png';
        end
        
        function id = getIDFromURL(url) %TBD
            matches = regexp(url, '%22.*?%22', 'match');
            
            if numel(matches) ~= 2
                id = [];
            else
                mFileName = matches{1};
                mFileName = mFileName(4:end-3);
                
                lineId = matches{2};
                lineId = lineId(4:end-3);
                
                id = simpol.adapter.RMIMatlabCodeAdapter.toItemId(mFileName, lineId);
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
        
        function [mFileName, id] = splitId(itemId)
            splits = strsplit(itemId, '|');
            mFileName = splits{1};
            id = splits{2};
        end
        
        function id = toItemId(mFileName, id)
            id = [mFileName '|' id];
        end
    end
    
end
