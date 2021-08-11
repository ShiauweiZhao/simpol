classdef RMISimulinkAdapter < simpol.adapter.AbstractBasicRMIAdapter
    
    properties(Access=private)
        lastGcbSID = '';
        lastSfgcoSID = '';
        lastTrackedSIDs = '';
    end
    %% --------------------------------------------------------------------
    % METHODS
    % ---------------------------------------------------------------------
    methods
        function h = RMISimulinkAdapter(mgr)
            h = h@simpol.adapter.AbstractBasicRMIAdapter(mgr);
        end
        
        % Overwrite addLink
        function b = addLinkImpl(h, itemId, newLinkId, data)
            h.ensureIsWritable();
            
            data.rmiItemId = itemId;
            b = defaultAddLink(h, ...
                itemId, newLinkId, data);
        end
        
        function updateCachedItemImpl(h, itemId)
            % This is probably pretty inefficient, if we check for every
            % block, but I am not aware of a faster way with RMI
            h.defaultUpdateCachedItem(itemId);            
        end

    end
    
    %% --------------------------------------------------------------------
    % ABSTRACT METHOD IMPLEMENTATION
    %% --------------------------------------------------------------------
    
    methods
        
        % Externall defined
        item = createItem(h, itemId);   
        itemIds = findItemIdsToCache(h)
        
        % -----------------------------------------------------------------
        
        function b = removeLinkImpl(h, link)
            b = h.defaultRemoveLink(link);
        end          
                
        % See base class
        function url = getNavURL(h, sid)
            % Get url of block
            url = rmi.getURL(sid);
        end
        

        function b = isLinkApplicable(~, link)
            % isLinkApplicable Checks if a rmi hyperlink is applicable for 
            % this kind of RMI adapter type.           
             b = ~isempty(strfind(link.toItemId, 'rmiobjnavigate')) && ...
                 ~isempty(strfind(link.toItemId, '.slx%22'));
        end
        
        % See base class
        function show(h, itemId)
            try
                open_system(Simulink.ID.getModel(itemId));
                % Distinguish between simulink and stateflow
                if isnumeric(Simulink.ID.getHandle(itemId))
                    eval(rmi('navCmd', Simulink.ID.getSID(itemId)));
                else
                    Simulink.ID.hilite(itemId);
                end
                
            catch
                warning('Cannot hilight system.');
            end
        end
        
    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods(Static)
        
        function b = supportsSnapshot()
            % supportsSnapshot Simulink adapter does support
            % making a snapshot.
            b = true;
        end
        
        % -----------------------------------------------------------------

        makeSnapshot(mItemId, imPath); % externally stored
        
        % -----------------------------------------------------------------
        
        % See base class
        function targets = detectTargets()
            targets = sort(find_system('SearchDepth', 0));
            targetFilePaths = cellfun(@(x) which(x), targets, 'UniformOutput', false);
            % Exclude built in libraries
            isBuiltIn = startsWith(targetFilePaths, matlabroot);
            targets = targets(~isBuiltIn);
        end
        
        % See base class
        function fileFilter = getTargetFileFilter()
            fileFilter = {'.slx'};
        end
        
        function  target = validateTarget(targetFilePath)
            [~,target, ext] = fileparts(targetFilePath);
            
            if ~any(strcmp(ext, simpol.adapter.RMISimulinkAdapter.getTargetFileFilter()))
                target = {};
            end
        end
        
        function b = isTargetAvailable(target)
            try
                simpol.adapter.RMISimulinkAdapter.loadTarget(target);
                b = true;
            catch
                b = false;
            end
        end
        
        function loadTarget(target)
            load_system(target);
        end
        
        function name = getName()
            name = 'Simulink / Stateflow';
        end
        
        function iconFileName = getItemIcon(item)
            % Stateflow has ID two :
            % HACK: Stateflow can have simulink (x:y:simulink:), so this is not fully
            % correct.
            if length(strfind(item.id, ':')) > 1
                iconFileName = 'simpol_stateflow.png';
            else
                iconFileName = 'simpol_simulink.png';
            end
        end          
        
        function id = getIDFromURL(url)
            
            url = convertCharsToStrings(url);
            
            
            [idx1, idx2] = regexp(url, "\[(.*?)\]");
            
            if isempty(idx1) || isempty(idx2)
                error("Invalid Simulink element URL.");
            end
            
            id = extractBetween(url, idx1+1, idx2-1);
            id = id.erase("%22");
            id = id.erase(".slx,");
            id = id.erase(".mdl,");
            
        end
        
        % See base class
        function b = providesSelection()
            b = true;
        end
        
        % See base class
        function itemIds = getSelectedItems(targets)
            
            persistent lastGcbSID;
            persistent lastTrackedSIDs;
            persistent lastSfgcoSID;
            
            
            itemIds = [];
            
            % If gcb is empty, there is neither SL nor SF open
            if isempty(gcb)
                return;
            end
            
            % Get currently selected model
            modelName = bdroot(gcb);
            
            % The selection mode tries to identify the last
            % selected primitive.
            % Available is gcb and sfgco.
            
            % Get selected Simulink element
            if ~isempty(modelName) && any(strcmp(modelName, targets))
                gcbSID = Simulink.ID.getSID(gcb);
            else
                gcbSID = [];
            end
            
            % Get selected stateflow element
            o = sfgco;
            
            if ~isempty(o)
                
                if numel(o) > 1
                    o = o(1);
                end
                
                if isa(o, 'Stateflow.Chart')
                    curModelname = bdroot(o.Path);
                else
                    curModelname = bdroot(o.Chart.Path);
                end
                
                isInTarget = any(strcmp(curModelname, targets));
                %                         disp(isInTarget);
                if ~isempty(o) && isInTarget
                    o = sfgco;
                    sfgcoSID = Simulink.ID.getSID(o);
                else
                    sfgcoSID = [];
                end
            else
                sfgcoSID = [];
            end
            
            % Decide which is the latest change
            if isempty(sfgcoSID) && isempty(gcbSID)
                itemId = lastGcbSID;
            elseif strcmp(lastSfgcoSID, sfgcoSID) && ...
                    strcmp(lastGcbSID, gcbSID)
                itemId = lastTrackedSIDs;
            elseif ~strcmp(lastSfgcoSID, sfgcoSID) && ...
                    ~strcmp(lastGcbSID, gcbSID)
                itemId = gcbSID;
            elseif ~isempty(sfgcoSID) && ~strcmp(lastSfgcoSID, sfgcoSID)
                itemId = sfgcoSID;
            elseif ~strcmp(lastGcbSID, gcbSID)
                itemId = gcbSID;
            else
                if ~isempty(lastSfgcoSID)
                    itemId = lastSfgcoSID;
                else
                    itemId = lastGcbSID;
                end
            end
            
            itemIds = itemId;
            
            if ischar(itemIds)
                itemIds = {itemIds};
            end
            
            lastGcbSID = gcbSID;
            lastTrackedSIDs = itemIds;
            lastSfgcoSID = sfgcoSID;
        end
        
    end
    
end
