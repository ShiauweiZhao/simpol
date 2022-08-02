classdef Manager < handle & simpol.utils.UserNotificationInterface
    % Manager Singleton central SimPol instance.
    
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
        methods (Static)
        function v = getVersion()
    
            pathname = fileparts(mfilename("fullpath"));
            pathname = fileparts(fileparts(pathname)); % Move to simpol/simpol folder 

            if isempty(pathname)
                sim_pol_version = 'unknown';   
            else
                version_file = pathname + "/simpol-version.m";

                if isfile(version_file) % Version file exists 

                   fid = fopen(version_file);
                   line_version = fgetl(fid); % Read first line 

                   if line_version == -1 % Empty file 
                       sim_pol_version = 'unknown';
                   elseif strlength(line_version) < 3 % Minimum test - invalid version 
                       sim_pol_version = 'unknown';
                   else
                       sim_pol_version = line_version;
                   end 

                else % Version file is missing

                    % Check if we are in a git repo %
                    [status, cmdout] = system("git rev-parse --is-inside-work-tree");

                    if status ~= 0 || cmdout == "false" % Git not available  
                        sim_pol_version = 'unknown';

                    else % Working on a git repo 

                        [status, cmdout] = system("git describe --tags");

                        if status == 0 % Tag exists 
                            sim_pol_version = cmdout;

                        else
                            [status, cmdout] = system("git rev-parse --short HEAD");

                            if status == 0 % Commit hash 
                                sim_pol_version = cmdout;
                            else
                                sim_pol_version = 'unkown';
                            end
                        end 
                    end
                end % File is missing 
            end
            v = sim_pol_version;  
        end % version

    end % static methods
   
end

