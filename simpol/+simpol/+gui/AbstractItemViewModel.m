classdef AbstractItemViewModel < handle & simpol.utils.UserNotificationInterface
    % AbstractItemViewModel This class abstracts the display method.
    
    properties(SetAccess=private,GetAccess=public)
        uiElement;
        adapter;
        linkTable;
        linkFilter simpol.gui.LinkFilter; 
        itemFilter simpol.gui.ItemFilter;
        
        linkCacheChangedListener;
        dirty = true; % Set to true if data or link table has been changed
    end
    
    properties(SetAccess=protected,GetAccess=public)
        selectedItemId string;
        selectedItemIdx double = 0;
        selectedLinkId string;
        selectedLinkIdx string = 0;
        itemSelected logical = false;
        linkSelected logical = false;        
    end
    
    
    methods(Abstract)
        updateViewModelImpl(h);
        
        % Function to which the selection changed event of the UI control
        % must be forwarded.
        selectionChanged(h, event);
        
        dirtyItem(h, itemId);
        dirtyAll(h);
        getNumItems(h);
        clearSelection(h);  
    end
    
    methods
        function h = AbstractItemViewModel(adapter, linkTable, uiElement)
            h.adapter = adapter;
            h.linkTable = linkTable;
            h.uiElement = uiElement;
            
            h.linkCacheChangedListener = ...
                listener(linkTable, 'LinkCacheChangedEvent',...
                @(varargin) h.setDirty());
        end
        
        function updateViewModel(h)
            
            if ~h.dirty
                return;
            end
            
            h.dirtyAll(); % To be removed?
            h.updateViewModelImpl();
            h.clearDirty();
        end
        
        function id = getSelectedItemId(h)
            id = h.selectedItemId;
        end
        
        function id = getSelectedLinkId(h)
            id = h.selectedLinkId;
        end
        
        function idx = getSelectedItemIdx(h)
            idx = h.selectedItemIdx;
        end
        
        function idx = getSelectedLinkIdx(h)
            idx = h.selectedLinkIdx;
        end        
        
        function b = isItemSelected(h)
            b = h.itemSelected;
        end
        
        function b = isLinkSelected(h)
            b = h.linkSelected;
        end
        
        function uiElement = getUIElement(h)
            uiElement = h.uiElement;
        end
        
        function setAdapter(h, adapter)
            h.adapter = adapter;
            h.dirty = true;
        end
        
        function setLinkTable(h, linkTable)
            h.linkTable = linkTable;
            h.dirty = true;
        end
        
        function setItemFilter(h, filter)
            h.itemFilter = filter;
            h.dirty = true;
        end
        
        function filter = getItemFilter(h)
            filter = h.itemFilter;
        end

        function setLinkFilter(h, filter)
            h.linkFilter = filter;
            h.dirty = true;
        end
        
        function filter = getLinkFilter(h)
            filter = h.linkFilter;
        end
        
        function setDirty(h)
            h.dirty = true;
        end    
        
        function clearDirty(h)
            h.dirty = false;
        end
    end
    
end

