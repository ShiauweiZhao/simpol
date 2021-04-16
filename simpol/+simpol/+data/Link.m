classdef Link < handle
    % Link Internally represents a link
    
    properties
        id string = "" % ID of a link is itemId | linkId
        itemId string = ""
        fromSide simpol.SideType = simpol.SideType.POLARION
        toItemId string = "" % Where the link goes to (counter side)
        unresolvedName string = "" % The name displayed, if the link cannot be resolved.
        suspected logical = false;
        toRevision string = "" % Revision of the destination at the timepoint the link was created.
    end
    
    methods
        function obj = Link(item, relativeLinkId)
            obj.id = obj.createLinkId(item.id, relativeLinkId);
            obj.itemId = item.id;
        end
    end
    
    methods(Static)
        function id = createLinkId(itemId, relativeLinkId)
            id = itemId + "|" + relativeLinkId;
        end
    end
end
