classdef LinkTable < handle
    %LINKTABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    % The difficulty with real bi-directional links is, that you have
    % duplicate links: (A) -> (B) and (B) -> (A). Each direction can be
    % resolvable or not.
    
    % The other difficulty is that you have NxM connections.
        
    % ---------------------------------------------------------------------
    
    properties(Constant)
        linkPropColumnNames = {'Link', 'Resolvable', 'ResolvedItemId', 'DisplayName',...
            'BiDirectional', 'CounterIndex', 'Suspected'}; % Link property column headers
        linkPropDefaultValues = {...
            simpol.data.Link.empty(0,1), false, "", "", false, 0, false};
    end   
    
    % ---------------------------------------------------------------------
    
    properties(SetAccess=private, GetAccess=public)
        suspicionModel; % Supicion algorithm used to detect suspicion of links
        tablePolarionLinks table; % Table of polarion links of all items
        tableMatlabLinks table; % Table of MATLAB links of all items
        linkPairs % Array Nx2 of links that are bi-directional
        polarionItemCacheChanged = true; % Stores data received by ItemCacheChangedEvent
        matlabItemCacheChanged = true; % Stores data received by ItemCacheChangedEvent
    end
    
     % ---------------------------------------------------------------------
    
    events
        LinkCacheChangedEvent; % Event fired after successful update
    end
    
    % ---------------------------------------------------------------------
    
    methods
        
        function h = LinkTable()
        end
        
        % -----------------------------------------------------------------
        
        function setSuspicionModel(h, suspicionModel)
            
            assert(isa(suspicionModel, 'simpol.suspicion.AbstractSuspicionModel'),...
                "1st input must be of type simpol.suspicion.AbstractSuspicionModel");
            
            h.suspicionModel = suspicionModel; 
            
            h.setItemCacheChanged(simpol.SideType.POLARION);
            h.setItemCacheChanged(simpol.SideType.MATLAB);
        end
        
        % -----------------------------------------------------------------
        
        function setItemCacheChanged(h, side)
            if side == simpol.SideType.POLARION
                h.polarionItemCacheChanged = true;
            else
                h.matlabItemCacheChanged = true;
            end
        end
                        
        % -----------------------------------------------------------------
        
        function n = getNumLinks(h, side)
            if side == simpol.SideType.POLARION
                n = size(h.tablePolarionLinks, 1);
            else
                n = size(h.tableMatlabLinks, 1);
            end
        end
        
        % -----------------------------------------------------------------
        
        function update(h, polarionAdapter, rmiAdapter, force)
            
            if nargin <= 3
                force = false;
            end
            
            % If no chache has changed, do nothing
            anyUpdate = h.polarionItemCacheChanged || h.matlabItemCacheChanged;
            if ~anyUpdate && ~force
                return;
            end
            
            % Reset links
            % ------------------------------           
            
            % Note that the counter side adapter is only required to check
            % if the link is applicable. This does not use the cache!
            % So it is correct to only update the changed side
            if h.polarionItemCacheChanged
                h.setLinks(simpol.SideType.POLARION,...
                    polarionAdapter, rmiAdapter)
            end
            if h.matlabItemCacheChanged
                 h.setLinks(simpol.SideType.MATLAB,...
                    polarionAdapter, rmiAdapter)
            end
            
            nPolarionLinks = size(h.tablePolarionLinks,1);
            nMatlabLinks = size(h.tableMatlabLinks,1);
            
            % Reset all link properties
            % ------------------------------
            
            if ~isempty(h.tablePolarionLinks)
                for i = 2:numel(h.linkPropColumnNames)
                    h.tablePolarionLinks(:, i) = repmat(...
                        h.linkPropDefaultValues(i), nPolarionLinks, 1);
                end
            end
            
            if ~isempty(h.tableMatlabLinks)            
                for i = 2:numel(h.linkPropColumnNames)
                    h.tableMatlabLinks(:, i) = repmat(...
                        h.linkPropDefaultValues(i), nMatlabLinks, 1);
                end 
            end
            
            % Check if links are resolvable
            % ------------------------------
            
            resolvedItemIds = strings(nPolarionLinks, 1);
            for i = 1:nPolarionLinks
                resolvedItemIds(i) = rmiAdapter.resolveLink(...
                    h.tablePolarionLinks.Link(i).toItemId);
            end
            h.tablePolarionLinks.ResolvedItemId = resolvedItemIds;
            h.tablePolarionLinks.Resolvable = (resolvedItemIds ~= "");
            
            resolvedItemIds = strings(nMatlabLinks, 1);
            for i = 1:nMatlabLinks
                resolvedItemIds(i) = polarionAdapter.resolveLink(...
                    h.tableMatlabLinks.Link(i).toItemId);
            end
            h.tableMatlabLinks.ResolvedItemId = resolvedItemIds;
            h.tableMatlabLinks.Resolvable = (resolvedItemIds ~= "");
            
            % Update display name
            % ------------------------------
            
            displayNames = strings(nPolarionLinks, 1);
            for i = 1:nPolarionLinks
                if h.tablePolarionLinks.Resolvable(i)
                    item = rmiAdapter.getCachedItem(char(h.tablePolarionLinks.ResolvedItemId(i)));
                    displayNames(i) = item.name;
                else
                    displayNames(i) = h.tablePolarionLinks.Link(i).unresolvedName;
                end
            end
            h.tablePolarionLinks.DisplayName = displayNames;  
            
            displayNames = strings(nMatlabLinks, 1);
            for i = 1:nMatlabLinks
                if h.tableMatlabLinks.Resolvable(i)
                    item = polarionAdapter.getCachedItem(char(h.tableMatlabLinks.ResolvedItemId(i)));
                    displayNames(i) = item.name;
                else
                    displayNames(i) = h.tableMatlabLinks.Link(i).unresolvedName;
                end
            end
            h.tableMatlabLinks.DisplayName = displayNames;             
            
            % Now make bi-directional pairing
            % ------------------------------
            
            IDX_POLARION = 1;
            IDX_MATLAB = 2;
                        
            % Create a one-sided pair for each polarion link
            pairs = cell(nPolarionLinks, 2);
            
            for i = 1:nPolarionLinks
                pairs{i, IDX_POLARION} = h.tablePolarionLinks.Link(i);
            end
                        
            % Now make the matching
            for i_m = 1:nMatlabLinks
                
                flgMatched = false;
                
                if h.tableMatlabLinks.Resolvable(i_m)
                    
                    for i_p = 1:nPolarionLinks

                        % Stop if this is an unmatched matlabLink. All
                        % unmatched MATLAB links are added at the bottom of the
                        % pairing list.
                        if isempty(pairs{i_p, IDX_POLARION})
                            break;
                        end
                        
                        % Skip if not resolvable
                        if ~h.tablePolarionLinks.Resolvable(i_p)
                            continue;
                        end

                        % Skip if already matched
                        if ~isempty(pairs{i_p, IDX_MATLAB}) % empty values are returned inside cell - bug?
                            continue;
                        end

                        % This is the core of bi-directional traceability -
                        % both links must be accepted from both side
                        matchA = h.tableMatlabLinks.Link(i_m).itemId == ...
                            h.tablePolarionLinks.ResolvedItemId(i_p);
                        matchB =  h.tablePolarionLinks.Link(i_p).itemId == ...
                            h.tableMatlabLinks.ResolvedItemId(i_m);
                        if matchA && matchB
                               

                            pairs{i_p, IDX_MATLAB} = h.tableMatlabLinks.Link(i_m);
                            h.tableMatlabLinks.BiDirectional(i_m) = true;
                            h.tablePolarionLinks.BiDirectional(i_p) = true;
                            h.tableMatlabLinks.CounterIndex(i_m) = i_p;
                            h.tablePolarionLinks.CounterIndex(i_p) = i_m;                            
                            flgMatched = true;
                            break;
                        end
                    end
                end % is MATLAB link resolvable
                
                if ~flgMatched
                    pairs{end+1, IDX_MATLAB} = h.tableMatlabLinks.Link(i_m); %#ok<AGROW>
                end
            end
            
            h.linkPairs = pairs;
            
            
            % Update suspicion
            % ------------------------------        

             [b_p, b_m] = h.suspicionModel.areLinksSuspected(...
                 polarionAdapter, h.tablePolarionLinks,...
                 rmiAdapter, h.tableMatlabLinks);
             
             h.tablePolarionLinks.Suspected = b_p;
             h.tableMatlabLinks.Suspected = b_m;
            
            % Update dirty flags
            % ------------------------------        
             
            h.polarionItemCacheChanged = false;
            h.matlabItemCacheChanged = false;
            h.notify("LinkCacheChangedEvent");
        end
        
        % -----------------------------------------------------------------
        
        function linkProps = getAllLinks(h, side)
            if side == simpol.SideType.POLARION
                linkProps = h.tablePolarionLinks;
            else
                linkProps = h.tableMatlabLinks;
            end
        end
        
        % -----------------------------------------------------------------
        
        function [links, linkPropTable] = getLinksOfItem(h, side, itemId)
            
            itemId = convertCharsToStrings(itemId);
            
            links = [];
            linkPropTable = [];
            
            if side == simpol.SideType.POLARION
                 if isempty(h.tablePolarionLinks)
                     return;
                 end
                 lgx = ([h.tablePolarionLinks.Link.itemId] == itemId);
                 links =  h.tablePolarionLinks.Link(lgx);
                 
                 if nargout > 1
                     linkPropTable = h.tablePolarionLinks(lgx,:);
                 end  
            else
                 if isempty(h.tableMatlabLinks)
                     return;
                 end                
                 lgx = ([h.tableMatlabLinks.Link.itemId] == itemId);
                 links =  h.tableMatlabLinks.Link(lgx);
                 
                 if nargout > 1
                     linkPropTable = h.tableMatlabLinks(lgx,:);
                 end                  
            end
            
        end
        
        % -----------------------------------------------------------------
        
        function [link, linkProps] = getLink(h, side, linkId)
            link = [];
            linkProps = [];
            
            t = h.getAllLinks(side);

            if isempty(t)
                return;
            end

            lgx = ([t.Link.id] == linkId);         
            
            link = t.Link(lgx);
            
            if nargout > 1
                linkProps = t(lgx,:);
            end
            
            assert(sum(lgx) <= 1, "0 or 1 matches expected.");
        end    
        
        % -----------------------------------------------------------------
        
        function [link1, link2] = getLinkAndCounterLink(h, side, linkId)
            
            [link1, link1Props] = h.getLink(side, linkId);
            link2 = [];
            
            if isempty(link1)
                return;
            end
            
            if link1Props.BiDirectional(1)
                t = h.getAllLinks(simpol.SideType.flip(side));
                link2 = t.Link(link1Props.CounterIndex(1));
            end
        end
        
        % -----------------------------------------------------------------
        
        function [links, linkProps] ...
                = queryLinks(h, side, itemId, queryString)
            
            if nargin < 4 % query string is optional
                queryString = "";
            end
            
            assert(isstring(itemId), "ItemId must be string.");
            assert(isstring(queryString), "Query string must be string.");
            
            links = [];
            linkProps = [];
            
            % Query links of item
            % ----------------------
            
            if itemId == ""
                t = h.getAllLinks(side);              
            else
                [~, t] = h.getLinksOfItem(side, itemId);         
            end
            
            if isempty(t)
                return;
            end
            
            % Query must be either a cell array with
            % identifiers
            % - resolvable
            % - bidirectional
            % - suspected
            % Connectors and/or and brackets () can be used.
            % Negation ~ can be used.
            % ------------------------------
            
            % Preprocessing
            queryString = lower(string(queryString));
            queryString = queryString.replace('and', '&');
            queryString = queryString.replace('or', '|');
            queryString = queryString.join();
            queryString = char(queryString);
                        
            if queryString ~= ""
                resolvable = logical(t.Resolvable); %#ok<NASGU> Needed for eval(queryString)
                bidirectional = logical(t.BiDirectional); %#ok<NASGU> Needed for eval(queryString)
                suspected = logical(t.Suspected); %#ok<NASGU> Needed for eval(queryString)

                % EVALUATE THE QUERY STRING
                lgx = eval(queryString);

                if ~any(lgx)
                    return;
                end

                t = t(lgx,:);
            end
            
            % Transform output
            % ----------------
            
            if isempty(t)
                return;
            end
            
            links = t.Link;
            
            if nargout > 1
                linkProps = t;
            end
        end         

    end
    
    % ---------------------------------------------------------------------
    
    methods(Access=private)
        
        function setLinks(h, srcSide, polarionAdapter, rmiAdapter)
            % setLinks Sets a new link set for one side.
            
            if srcSide == polarionAdapter.getSide()
                srcAdapter = polarionAdapter;
                dstAdapter = rmiAdapter;
            else
                srcAdapter = rmiAdapter;
                dstAdapter = polarionAdapter;
            end
                       
            srcItems = srcAdapter.cachedItems.values;
            
            applicableLinks = [];
            for i = 1:numel(srcItems)              
                item = srcItems{i};
                
                for j = 1:numel(item.links)
                    link = item.links(j);
                    if dstAdapter.isLinkApplicable(link)
                        applicableLinks = [applicableLinks link]; %#ok<AGROW>
                    end
                end
            end
            
            % Save links in class and notify dirty
            if ~isempty(applicableLinks)
                
                t = cell2table(repmat(h.linkPropDefaultValues, numel(applicableLinks), 1),...
                    'VariableNames', h.linkPropColumnNames);
                t.Link = reshape(applicableLinks, [], 1);
                
                if srcSide == polarionAdapter.getSide()
                    h.tablePolarionLinks = t;
                else
                    h.tableMatlabLinks = t;
                end
            else
                if srcSide == polarionAdapter.getSide()
                    h.tablePolarionLinks = [];
                else
                    h.tableMatlabLinks = [];
                end                
            end       
        end        
    end
    
end

