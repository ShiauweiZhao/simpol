function sl_customization(cm)
    cm.addCustomMenuFcn('Simulink:ToolsMenu', @getMenuItems);
    cm.addCustomMenuFcn('Simulink:PreContextMenu', @getContextMenuItems);
    cm.addCustomMenuFcn('Stateflow:PreContextMenu', @getContextMenuItems);
end

function schemaFcns = getMenuItems
    schemaFcns = {@getMenuToolItem};
end

function schemaFcns = getContextMenuItems
    schemaFcns = {@getContextMenuLinkerItem};
end

function schema = getMenuToolItem(~)
    schema = sl_container_schema;
    schema.label = 'SimPol';     
	schema.childrenFcns = {...
        @getMenuLinkerItem,...
        @getMenuManagerItem};
end

function schema = getMenuLinkerItem(~)
    schema = sl_action_schema;
    schema.label = 'Linker';
    schema.statustip = 'Open SimPol Linker';
    schema.accelerator = 'Ctrl+Alt+R';
    schema.callback = @cb_openSimPolLinker;
end

function schema = getContextMenuLinkerItem(~)
    schema = sl_action_schema;
    schema.label = 'SimPol Linker';
    schema.statustip = 'Open SimPol Linker';
    schema.accelerator = 'Ctrl+Alt+R';
    schema.callback = @cb_openSimPolLinker;
end

function schema = getMenuManagerItem(~)
    schema = sl_action_schema;
    schema.label = 'Manager';
    schema.statustip = 'Open SimPol Manager';
    schema.callback = @cb_openSimPolManager;
end

function cb_openSimPolLinker(~)

    mgr = SimPol('instance');

    mgr.show(true);
end

function cb_openSimPolManager(~)

    mgr = SimPol('instance');

    mgr.show(false);
end