classdef AbstractAdapter < handle & simpol.utils.UserNotificationInterface
    % AbstractAdapter Basic, abstract class for adapters. Defines the
    % functions to be implemented.
    % Core is the item cache, for which the class provides getter and
    % setter methods.
    
    properties(GetAccess=public, SetAccess=protected)      
        cachedItems;        % containers.Map with cached items
    	mgr;                % SimPol Manager instance
        settings;           % SimPol settings
        linkModel;          % Link model algorithms
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------     
    
    events
        % Event to be fired if the item cache has changed (update methods).
        ItemCacheChangedEvent; 
    end

    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------  
    
    methods(Abstract)

        % Refreshes the values of all cached items.
        updateCacheImpl(h);
        
        % Refreshes the values of a cached item.
        updateCachedItemImpl(h, itemId);
                
        % Checks if the adapter is in read-only mode. This may have
        % different reasons (e.g., baseline view in Polarion).
        b = isReadOnly(h);    
                
        % Shows/opens and item.
        show(h, itemId);
        
        % Returns true if the link is applicable for the adapter. That
        % means that it has the format to be resolved, but not that it can
        % be resolved.
        % link simpol.data.Link object
        b = isLinkApplicable(h, link);
                
        % Returns the resolved item id, if the address is resolvable. Returns
        % "" otherwise. A link is resolvable,
        % if the the target item can be found in the set of loaded targets.
        item = resolveLink(h, linkDestAddress);
                
        % Returns whether a link is suspected. A link is suspected, if the
        % checksums stored with the respective
        % link does not match to those of the uptream item.
        b = isLinkSuspected(h, linkPropertyTable);
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------    
    
    methods(Abstract, Static)
        % Returns the readable name of the adapter
        name = getName();
        
        % Returns the icon file name used for items
        iconFileName = getItemIcon(item);
        
        % Returns the side, on which the adapter can be used. Return value
        % is of type simpol.SideType.
        side = getSide();
    end

    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    methods
        
        % Constructor, which must be called
        function h = AbstractAdapter(mgr)
            h.cachedItems = containers.Map('keyType', 'char',...
                'valueType', 'any');
			h.mgr = mgr;
            h.settings = mgr.settings;
            h.linkModel = mgr.getLinkModel();
        end
        
        % -----------------------------------------------------------------
        
        function updateCache(h)
            h.updateCacheImpl();
            h.notify("ItemCacheChangedEvent");
        end
        
         % ----------------------------------------------------------------
        
        function updateCachedItem(h, itemId)
            h.updateCachedItemImpl(itemId);
            h.notify("ItemCacheChangedEvent");
        end
        
        % -----------------------------------------------------------------
        
        function ensureIsWritable(h)
            % ensureIsWritable Function checks whether the adapter is 
            % read-only. If yes, an error is thrown.           
            if isempty(h.mgr) || h.mgr.isReadOnly()
                error("This action cannot be performed. Connection is read-only.");
            end
        end        
        
        % -----------------------------------------------------------------
        
        function item = getCachedItem(h, itemId)
            % getCachedItem Returns the cached item with itemId.
            % itemId    String or char id
            % Returns [] if not found.
            % Id can be either string or char.
            
            if isempty(itemId)
                item = [];
                return;
            end
            
            itemId = convertStringsToChars(itemId);
            if ~h.cachedItems.isKey(itemId)
                item = [];
            else
                item = h.cachedItems(itemId);
            end
        end   
        
        % -----------------------------------------------------------------
        
        function items = getCachedItems(h, itemIds)
           % getCachedItems Returns all cached items with the given IDs.
           % Throws an error if any ID is not present. 
           % itemId    String or char id
           % Ids can be either strings or chars.
           % Special case: Returns [] if itemIds is empty.
           
           if isempty(itemIds)
               items = [];
               return;
           end
           
            if nargin == 1
                items = h.cachedItems.values();
            else
                itemIds = convertStringsToChars(itemIds);
                if ~iscell(itemIds)
                    itemIds = {itemIds};
                end                
                items = h.cachedItems.values(itemIds);
            end
        end
        
        % -----------------------------------------------------------------
        
        function b = isCachedItem(h, itemIds)
            % isCachedItem Check if ids exist in the cache. Input can be
            % one or more item IDs.
            % itemId    String or char id
            % Special case: Returns false if itemIds is empty.
            % Returns a logical vector where each field indicates if the
            % item exists or not.
            
            if isempty(itemIds)
                b = false;
                return;
            end
            
            itemIds = convertStringsToChars(itemIds);
            b = h.cachedItems.isKey(itemIds);
        end   
    end
end

