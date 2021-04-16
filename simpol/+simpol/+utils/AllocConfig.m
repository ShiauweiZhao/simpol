classdef AllocConfig < matlab.mixin.SetGet
    
    properties(Access=public)
        
        % Polarion ServerURL
        ServerURL char = '';
        
        % Polarion Project ID
        ProjectID char = '';
        
        % Polarion QueryString
        QueryString char = '';
        
        % Polarion BaselineRevision
        BaselineRevision char = '';
        
        % Hierarchy Link Roles
        HierarchyLinkRoles = {'parent'};
        
        % PushImage
        PushImage logical = false;
        
        % Link Model
        % - Direct Linking
        % - Surrogate Linking
        LinkModel char = 'Direct Linking';
        
        % Surrogate Work Item Type
        SurrogateWorkItemType char = '';
        
        % Surrogate Link Role
        SurrogateLinkRole char = '';
        
        % Suspicion mode
        SuspicionModel char = 'Revision';
        
        %SL/SF Selection Rule
        SLSFSelectionRule char = 'simpol_SLSFSelectionRule';
        
        %Target type
        TargetType char = 'simpol.adapter.RMISimulinkAdapter';
        
        % Targets
        Targets = [];
    end
    
    methods
        
        function h = AllocConfig(filepath)
            
            if nargin > 0 && ~isempty(filepath) && exist(filepath, 'file')
                
                % Read JSON file
                fid = fopen(filepath, 'r');
                jsonString = fread(fid, '*char')';
                settingsStruct = jsondecode(jsonString);
                fclose(fid);
                
                % Copy values from struct to properties
                fieldNames = fieldnames(settingsStruct);
                for i = 1:numel(fieldNames)
                    if isfield(settingsStruct, fieldNames{i})
                        h.set(fieldNames{i}, settingsStruct.(fieldNames{i}));
                    end
                end
            else
                % Take default values                
            end
            
        end
        
        function save(h, filepath)
            
            if isempty(filepath)
                error('Allocation file cannot be written if file path is not set.');
            end
            
            fid = fopen(filepath, 'w');
            fwrite(fid, jsonencode(h));
            fclose(fid);
        end
        
        %% SETTERS checking the validity of the values
        % -----------------------------------------------------------------
        
        function h = set.HierarchyLinkRoles(h, val)
            if ischar(val)
                h.HierarchyLinkRoles = {val};
            elseif iscell(val)
                h.HierarchyLinkRoles = val;
            elseif isempty(val)
                h.HierarchyLinkRoles = [];
            else
                error(['Hierarchy link role must be a string or a cell array of strings, but is a ' class(val) '.']);
            end
        end
        
        function h = set.TargetType(h, val)
            
            % For backward compatibility, make mapping
             % Register target types
            switch(val)
                case 'simpol.bridge.RMISimulinkBridge'
                    val = 'simpol.adapter.RMISimulinkAdapter';
                case 'simpol.bridge.RMISimulinkTestBridge'
                    val = 'simpol.adapter.RMISimulinkTestAdapter';
                case 'simpol.bridge.RMISimulinkDataBridge'
                    val = 'simpol.adapter.RMISimulinkDataAdapter';
                case 'simpol.bridge.RMIMatlabCodeBridge'
                    val = 'simpol.adapter.RMIMatlabCodeAdapter';   
            end           
            
            if ~any(strcmp(superclasses(val), 'simpol.adapter.AbstractAdapter'))
                error('Invalid bridge class, which does not interhit from simpol.adapter.AbstractAdapter.');
            end
            h.TargetType = val;
        end
        
        function h = set.LinkModel(h, val)
            if ~any(strcmp(val, {'Direct Linking', 'Surrogate Linking'}))
                error('Use ''Direct Linking'' or ''Surrogate Linking''.');
            end
            h.LinkModel = val;
        end
        
        function h = set.SuspicionModel(h, val)
            if ~any(strcmp(val, {'Revision', 'AutoSuspect'}))
                error('Use ''Revision'' or ''AutoSuspect''.');
            end
            h.SuspicionModel = val;
        end
        
        function h = set.Targets(h, val)
            if ischar(val)
                h.Targets = {val};
            elseif iscell(val)
                h.Targets = val;
            elseif isempty(val)
                h.Targets = [];
            else
                error(['Targets must be a string or a cell array of strings, but is a ' class(val) '.']);
            end        
        end
    end
    
    
end

