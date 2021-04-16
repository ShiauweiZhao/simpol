function [bSuccess, bBiSuccess] = removeLink(h, side, linkId)
    % Removes the link defined by "link1Identifier"
    % from item "item1Id". sourceAdapterName identifies the side of
    % the item and link ("rmi" or "polarion").
    % linkId    ID of the link
    % side      Side to which the link belongs

    % Ensure that SimPol is in writable mode. If not, throw an
    % error.            
    h.ensureIsWritable();            

    bBiSuccess = false;

    % Get link and counter link
    adapter = h.getAdapterBySide(side); 
    counterAdapter = h.getAdapterBySide(simpol.SideType.flip(side));

    [link1, link2] = h.linkTable.getLinkAndCounterLink(...
        side, linkId);                        

    % Remove link1 - if we can resolve it, we use the itemId,
    % otherwise we use the index
    if side == simpol.SideType.MATLAB
        bSuccess = adapter.removeLink(link1);
    else
        bSuccess = h.linkModel.removeLinkToSimulink(...
            h.matlabAdapter, h.matlabAdapter, link1);
    end

    % Remove counter link (link2)
    if bSuccess && ~isempty(link2)
        if side == simpol.SideType.MATLAB
            bBiSuccess = h.linkModel.removeLinkToSimulink(...
                h.polarionAdapter, h.matlabAdapter, link2);                    
        else
            bBiSuccess = counterAdapter.removeLink(link2);
        end
    end

end