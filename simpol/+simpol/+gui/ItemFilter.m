classdef ItemFilter
    % ItemFilter Allows filtering of cached items based on item and link
    % properties.
    properties
        target string = ""
        searchString string = ""
        linkStatus string = ""
    end
    
    methods
        function obj = ItemFilter(target, varargin)
            % Returns the filtered item ids.
            % target            On RMI side, the target (e.g., model). [] if no target
            %                   filter shall be applied.
            %
            % Name-Value Pairs:
            % SearchString  SearchString, which must be found in item id,
            %               description, and name.
            % LinkStatus    Either 'all', 'linked only' or 'unlinked only'.
            
            % Parse input
            p = inputParser;
            p.CaseSensitive = false;
            p.addParameter('SearchString', '');
            p.addParameter('LinkStatus', 'all', ...
                @(x) any(strcmpi(x, {'all', 'linked only', 'unlinked only'})));
            p.parse(varargin{:});
            
            obj.target = convertCharsToStrings(target);
            obj.searchString = convertCharsToStrings(p.Results.SearchString);
            obj.linkStatus = convertCharsToStrings(p.Results.LinkStatus);
        end
        
        function ids = exec(obj, adapter, linkTable)
            % exec Performs the filtering of the passed cachedItems (from
            % adapter). Returns the ids of the remaining items.
                
            ids = adapter.cachedItems.keys();
            
            if isempty(ids)
                return;
            end
            
            ids = convertCharsToStrings(ids);
            
            % Apply target filter
            if obj.target == ""
                ids = ids(startsWith(ids, obj.target));
            end
            
            % Apply link status filter
            if ~strcmpi(obj.linkStatus, "all")
                
                nLinks = zeros(1, numel(ids));
                for i = 1:numel(ids)
                    nLinks(i) =  numel(linkTable.getLinksOfItem(adapter.getSide(),...
                        string(ids{i})));
                end
                
                if strcmpi(obj.linkStatus, "linked only")
                    markers = nLinks > 0;
                else
                    markers = nLinks == 0;
                end
                ids = ids(markers);
            end
            
            % If no search string is specified, early return
            if obj.searchString == ""
                return;
            end
            
            % Filter by search string
            items = adapter.getCachedItems(ids);
            if startsWith(obj.searchString, "id:")
                
                if strlength(obj.searchString) > 3
                    searchIds = sort(strtrim(strsplit(extractAfter(obj.searchString, 3), ",")));
                    
                    markers = adapter.isCachedItem(searchIds);
                    
                    ids = searchIds(markers);
                else
                    ids = [];
                end
                
            else % General search in ID, name, and description
                
                markers = cellfun(@(x) ~isempty(regexpi(x, obj.searchString, 'once')), ids);
                
                markers = markers | ...
                    cellfun(@(x)~isempty(regexpi(x.name, obj.searchString, 'once')),...
                    items);
                
                markers = markers | ...
                    cellfun(@(x)~isempty(regexpi(x.description, obj.searchString, 'once')),...
                    items);
                
                ids = ids(markers);
                
            end
        end
        
    end
end

