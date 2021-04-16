function makeSnapshot(mItemId, imgPath)
% makeSnapshot Makes a snapshot of a Simulink/Stateflow model.
% Timestamps and author are replaced, to get a reproduciable checksum.
%
% mItemId   SID of the model/subsystem/chart/....
% dstDir    Directory into which the image shall be written

h = Simulink.ID.getHandle(mItemId);

if isempty(h)
    return;
end

% Numeric handles are returned from Simulink blocks
isSimulink = isnumeric(h);

% When we have a Subsystem, check if it is a Stateflow chart,
% because they should be plotted by sfprint (to get inside
% view)
if ~(isprop(h,'Type') && strcmp(get_param(h, 'Type'), 'annotation'))
    if isSimulink && ...
            ~strcmp(get_param(h, 'Type'), 'block_diagram') && ...
            strcmp(get_param(h, 'BlockType'), 'SubSystem')
        
        rt = sfroot;
        htmp = rt.find('-isa', 'Stateflow.Chart', '-and', 'Path', Simulink.ID.getFullName(h));
        
        if ~isempty(htmp)
            isSimulink = false;
            h = htmp;
        end
    end
end

% Compose file name and path

if isSimulink
    o = get_param(h, 'object');
    
    if ~isa(o, 'Simulink.BlockDiagram') && ~isa(o, 'Simulink.SubSystem')
        sysSid = Simulink.ID.getSID(o.Parent);
    else
        sysSid = mItemId;
    end
    
    % Unhilight all
    blocksInContext = find_system(Simulink.ID.getFullName(sysSid), 'SearchDepth', 1);
    cellfun(@(x) set_param(x, 'HiliteAncestors', 'none'),...
        blocksInContext);
    
    if ~isa(o, 'Simulink.BlockDiagram')
        Simulink.ID.hilite(mItemId);
    end
    
    print('-dpng', ['-s' Simulink.ID.getFullName(sysSid)], imgPath);
    
    if ~isa(o, 'Simulink.BlockDiagram')
        Simulink.ID.hilite(mItemId, 'none');
    end
else % It is stateflow
    o = h;
    % If it is neither a box nor a chart
    if ~isa(o, 'Stateflow.Box') &&  ~isa(o, 'Stateflow.Function') && ...
            ~(isa(o, 'Stateflow.Chart') && ~(isfield(o, 'IsSubchart') && o.IsSubchart))
        if isa(o.SubViewer, 'Stateflow.Chart') || isa(o.SubViewer, 'Stateflow.Box')
            sysSid = Simulink.ID.getSID(o.SubViewer);
            sysObj = o.SubViewer;
        else
            sysSid = Simulink.ID.getSID(o.Chart);
            sysObj = o.Chart;
        end
    else
        sysSid = mItemId;
        sysObj = o;
    end
    
    % Highlight
    if ~isa(o, 'Stateflow.Chart') && ~isa(o, 'Stateflow.Box') &&...
            ~isa(o, 'Stateflow.Function')
        Simulink.ID.hilite(mItemId)
    end
    
    sfprint(sysObj, 'png', imgPath);
    
    % Revert highlighting
    if ~isa(o, 'Stateflow.Chart') && ~isa(o, 'Stateflow.Box') &&...
            ~isa(o, 'Stateflow.Function')
        Simulink.ID.hilite(mItemId, 'none')
    end
end

% Postprocessing image
% ----------------------

if strcmp(mItemId, sysSid)
    sText = sysSid;
else
    sText = [mItemId ' (in ' sysSid ')'];
end

I = imread(imgPath);
I2 = simpol.utils.Image.addBorder(I, 20, [255 255 255], 'outer');
I2 = simpol.utils.Image.expand(I2, 20);
I2 = simpol.utils.Image.addHorizontalLine(I2, 20, [0 0 0]);
I2 = simpol.utils.Image.addText(I2, sText, 8, [0 0 0], [5 6]);
I2 = simpol.utils.Image.addBorder(I2, 1, [0 0 0], 'inner');
% Remove specific information, like author and modification
% time to allow binary comparison
imwrite(I2, imgPath, 'Author', 'SimPol', 'ImageModTime', '17-Jan-2013 11:23:10');

end
