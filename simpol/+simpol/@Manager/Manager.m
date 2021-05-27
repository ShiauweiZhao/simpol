classdef Manager < handle & simpol.utils.UserNotificationInterface
    % Manager Singleton central SimPol instance.
    
    properties(Constant)
        version = '##VERSION##';
        build = '##BUILD##';
    end
    
    properties
        hSimPolGUI = -1;
        guiUpdateTimer; % Must be external to gui, since the destructor of
        % the app cannot be changed.
    end
    
    properties(GetAccess=public, SetAccess=private)
        allocationFilePath char = '';
        matlabAdapter = [];   
        polarionAdapter = [];
        settings = [];
        registeredTargetTypes = [];  
        linkTable simpol.link.LinkTable = simpol.link.LinkTable;
    end
    
    properties(Access=private)
        polarionAdapterNotifyListener = [];
        polarionAdapterItemCacheChangedListener = [];
        matlabAdapterNotifyListener = [];
        matlabAdapterItemCacheChangedListener = [];
        linkCacheChangedListener = [];

        % Defines the linking method used for Polarion
        % linkModel@simpol.linkmodel.AbstractLinkModel();
        linkModel;
    end
            
    methods
        
        % External functions
        addLink(h, workItemId, destItemAddress);
        [bSuccess, bBiSuccess] = removeLink(h, side, linkId);
        updateSettings(h);
        
        % -----------------------------------------------------------------
        
        function h = Manager()
            
            if ispref('SimPol', 'Debug')
                assignin('base', 'debugStream', simpol.utils.DebugStream(h));
            end
            
            
            % Register target types
            h.registeredTargetTypes =...
                {'simpol.adapter.RMISimulinkAdapter',...
                'simpol.adapter.RMISimulinkTestAdapter',...
                'simpol.adapter.RMISimulinkDataAdapter',...
                'simpol.adapter.RMIMatlabCodeAdapter'};
        end 
        
        % -----------------------------------------------------------------
        
        function setAllocationFile(h, filepath)
            
			f = java.io.File(filepath);
			
            if ~f.isAbsolute()
                error("Allocation file path must be absolute.");
            end
            
            h.allocationFilePath = filepath;
            
            h.updateSettings();
        end
        
        % -----------------------------------------------------------------
        
        function delete(h)
            % delete Destructor
            if ~isempty(h.guiUpdateTimer)
                stop(h.guiUpdateTimer);
            end
        end
        
        % -----------------------------------------------------------------
        
        function linkModel = getLinkModel(h)
            linkModel = h.linkModel;
        end
                
        % -----------------------------------------------------------------
        
        function b = isReadOnly(h)
            b =  isempty(h.polarionAdapter) || isempty(h.matlabAdapter) ||...
                    h.polarionAdapter.isReadOnly() || h.matlabAdapter.isReadOnly();
        end
        
        % -----------------------------------------------------------------
        
        function ensureIsWritable(h)
            if h.isReadOnly
                error("Session is read-only.");
            end
        end
        
        % -----------------------------------------------------------------

        function updateLinkTable(h)          
            if ~isempty(h.matlabAdapter) && ~isempty(h.polarionAdapter) 
                h.linkTable.update(h.polarionAdapter, h.matlabAdapter);
            end

        end
        
        % -----------------------------------------------------------------
        
        function b = unsuspectLink(h, side, linkId)
            
            h.ensureIsWritable();
                                    
            b = false;
            
            link = h.linkTable.getLink(side, linkId);
            
            if isempty(link)
                return;
            end
                        
            % Remove link, and add link again
            if ~h.removeLink(side, linkId)
                return;
            end
            
            % Add link
            if side == simpol.SideType.POLARION
                h.addLink(link.itemId, link.toItemId);
            else
                h.addLink(link.toItemId, link.itemId);
            end
            
            b = true;
            
        end
        
        % -----------------------------------------------------------------
        
        function adapter = getAdapterBySide(h, side)
            if side == simpol.SideType.POLARION
                adapter = h.polarionAdapter;
            else
                adapter = h.matlabAdapter;
            end
        end
        
        % -----------------------------------------------------------------
                
        function show(h, singleSide)
            if h.hSimPolGUI == -1 || ~isvalid(h.hSimPolGUI)
                h.hSimPolGUI = SimPol;
            else
                h.hSimPolGUI.UIFigure.Visible = 'on';
            end
            
            if nargin == 1
                singleSide = false;
            end
            
            if singleSide
                h.hSimPolGUI.singleSideView(1);
            else
                h.hSimPolGUI.singleSideView(0);
            end
        end 
        
        % -----------------------------------------------------------------
        
        function forwardNotifyEvents(h, ~, eventData)
            notify(h, "UserNotificationEvent", eventData);
        end
        
    end
    
end

