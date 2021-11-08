classdef SyncSurrogateWorkItems < simpol.maintenance.AbstractJob
    % SyncSurrogateWorkItems Job that searches for surrogate work items
    % that are out of sync. For further details see description.
     
    methods(Static)
        
        function name = getName()
           name = "Synchronize Surrogate Work Items"; 
        end
        
        % -----------------------------------------------------------------
        
        function s = getDescription()
            s = "Patches surrogate work itmes by " + newline + ...
                "(1) deleting dead uptraces." + newline + ...
                "(2) searching for surrogate work items in Polarion, which have no uptrace from a model element. " + ...
                "These surrogate items are not required, but also no design flaw. " + newline + ...
                "(3) searching for surrogate work items in Polarion, which do not exist in the model any more. These are are design flaw." + newline + ...
                "(4) searching for surrogate work items, which do not fit to the loaded models." + newline + ...
                "(5) reestabishing hyperlinks." + newline + newline + ...
                "Use 'Update Images' separately to update embedded pictures of systems.";
        end
    end
    
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------    
    
    methods
        
        function executeImpl(h)
            
            % Step 1: Deprecate work item if no model exists any more
            % Step 2: Remove all dead upstream links
            
            mgr = SimPol('instance');
                        
            % -------------------------------------------------------------
            % Process surrogate work items
            % -------------------------------------------------------------
            
             h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(0.1, "Querying surrogate work items..."));              
            
            qFields = {'id', 'title', 'hyperlinks', 'linkedWorkItems'};
            q = h.composeQueryString(mgr, false);

             jSurrogateWorkItems = mgr.polarionAdapter.queryWorkItems(q,...
                 'id', qFields);
             
             if isempty(jSurrogateWorkItems)
                 return;
             end
             
             progressShare = .1;
             progressOffset = .2;             
      
             % Find and remove dead uplinks
             bChange = false;
             for iWorkItem = 1:numel(jSurrogateWorkItems)
                 
                h.notify('JobProgressEvent',...
                    simpol.maintenance.JobProgress(...
                    progressShare*(iWorkItem-1)/numel(jSurrogateWorkItems) + progressOffset,...
                    "Removing dead links..."));               
                
                 jSurrogateWorkItem = jSurrogateWorkItems(iWorkItem);

                 jUpLinks = jSurrogateWorkItem.getLinkedWorkItems();
                 for iLinks = 1:numel(jUpLinks)
                     wiLinked = mgr.polarionAdapter.getWorkItem(...
                         char(jUpLinks(iLinks).getWorkItemURI()), {'id'});
                     
                     % If the uplink target does not exist, remove link
                     if isempty(wiLinked.getId())
                         mgr.polarionAdapter.removeWorkItemLink(...
                             char(jSurrogateWorkItem.getUri()), ...
                             char(jUpLinks(iLinks).getWorkItemURI()),...
                             mgr.settings.SurrogateLinkRole);
                         
                         bChange = true;
                     end
                     
                     % Bring up-to-date
                     title = char(jSurrogateWorkItem.getTitle());
                     if mgr.matlabAdapter.cachedItems.isKey(title)
                         
                        % Reestablish hyperlink - check if already exists
                        % is done by addHyperlink
                        mgr.polarionAdapter.addHyperlink(jSurrogateWorkItem,...
                            mgr.matlabAdapter.getNavURL(title));
                        
                     end
                     
                 end
             end
             
            h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(...
               .4, "Recaching..."));  
             
             % Recache if any link has been removed
             if bChange
                 jSurrogateWorkItems = ts.queryWorkItems(q,...
                 'id', qFields);
                 bChange = false;
             end
             
            h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(...
               .6, "Collecting deprecated surrogate items..."));  

             unusedIDs = {};
             unusedTitles = {};
             deprecatedIDs = {};
             deprecatedTitles = {};
             for iWorkItem = 1:numel(jSurrogateWorkItems)
                
                 jSurrogateWorkItem = jSurrogateWorkItems(iWorkItem);             

                 % Deprecate surrogate workitems that have no
                 % implementation in the model any more or that have no
                 % upstream links
                 if isempty(jSurrogateWorkItem.getLinkedWorkItems())
                     unusedIDs{end+1} = char(jSurrogateWorkItem.getId());
                     unusedTitles{end+1} = char(jSurrogateWorkItem.getTitle());
                 end
                 
                 if ~mgr.matlabAdapter.cachedItems.isKey(char(jSurrogateWorkItem.getTitle()))
                     deprecatedIDs{end+1} = char(jSurrogateWorkItem.getId());
                     deprecatedTitles{end+1} = char(jSurrogateWorkItem.getTitle());
                 end

             end
             
             
             % ------------------------------------------------------------
             % Get all surrogate items which are not resolvable
             % ------------------------------------------------------------
             
             h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(...
               .8, "Collecting unresolvable surrogate items..."));               
             
             q = h.composeQueryString(mgr, true);
             unresolvedIDs = {};
             unresolvedTitles= {};
             jSurrogateWorkItems = mgr.polarionAdapter.queryWorkItems(q,...
                 'id', {'id', 'title'});
             for i = 1:numel(jSurrogateWorkItems)
                 unresolvedIDs{end+1} = char(jSurrogateWorkItems(i).getId());
                 unresolvedTitles{end+1} = char(jSurrogateWorkItems(i).getTitle());
             end
             
             h.notify('JobProgressEvent',...
                simpol.maintenance.JobProgress(...
               1, "Preparing results..."));
             
             % ------------------------------------------------------------
             % Showing results
             % ------------------------------------------------------------
             
             if ~isempty(unusedIDs)
                [~, ok] = listdlg('PromptString', {'The following surrogate work items do not have an uptrace from a model element and may be deprecated.'...
                    'SimPol cannot delete work items itself. If you press ok, a query is openend in '...
                    'your web browser and you can easily delete the items via the web UI.'},...
                    'SelectionMode', 'single',...
                    'ListString', cellstr(string(unusedIDs) + ' (' + unusedTitles + ')'), 'ListSize', [700 200]);
                  if ok
                     web(mgr.polarionAdapter.getQueryRestRequest(['id:' strjoin(unusedIDs, ' OR id:') ]), '-browser');
                 end
             end
             
             if ~isempty(deprecatedIDs)
                [~, ok] = listdlg('PromptString', {'The following surrogate work items do'...
                    'not match a RMI element. SimPol cannot delete work items itself. If you press ok,' ...
                    'a query is openend in your web browser and you can easily delete the items.'},...
                    'SelectionMode', 'single',...
                    'ListString', cellstr(string(deprecatedIDs) + ' (' + deprecatedTitles + ')'), 'ListSize', [450 200]);
                 if ok
                     web(mgr.polarionAdapter.getQueryRestRequest(['id:' strjoin(deprecatedIDs, ' OR id:') ]), '-browser');
                 end
                 
             end
             
             if ~isempty(unresolvedIDs)
                [~, ok] = listdlg('PromptString', {'The following surrogate work items do'...
                    'not match a loaded RMI element. SimPol cannot delete work items itself. If you press ok,' ...
                    'a query is openend in your web browser and you can easily delete the items.'},...
                    'SelectionMode', 'single',...
                     'ListString', cellstr(string(unresolvedIDs) + ' (' + unresolvedTitles + ')') , 'ListSize', [450 200]);
                 if ok
                     web(mgr.polarionAdapter.getQueryRestRequest(['id:' strjoin(unresolvedIDs, ' OR id:') ]), '-browser');
                 end
                 
             end             
        end
    end
    
    methods(Access=private)
        
        function q = composeQueryString(h, mgr, negative)
            
            if strcmp(mgr.settings.TargetType, 'simpol.adapter.RMISimulinkAdapter')
                separator = '\:';
            else
                separator = '|';
            end
            
            s = {};
            for i = 1:numel(mgr.settings.Targets)
                name = mgr.settings.Targets{i};
                s{end+1} = ['title:' name separator '* OR title:' name];
            end
            s = strjoin(s, ' OR ');
            
            if negative
                sNot = 'NOT';
            else
                sNot = '';
            end

            % Compose query string and cache data
            % Example: 'project.id:stanag4586 AND (title:modelname\:* OR title:modelname) AND type:sl_DesignModel'
            q = ['project.id:' mgr.settings.ProjectID ' AND '...
                 sNot '(' s ') AND '...
                 'type:' mgr.settings.SurrogateWorkItemType];
        end
        
    end

    
end

