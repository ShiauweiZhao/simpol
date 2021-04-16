classdef SLReq < handle
    
    properties(Constant)
        reqSetName = 'simpol_synced_reqset';
    end
    
    methods(Static)
        function pushToSL(modelnames)
            
            % Without arguments, only the requirement file is written
            if nargin > 0
                if ~iscell(modelnames)
                    modelnames = {modelnames};
                end
            else
                modelnames = [];
            end
            
            if SimPol('test')
                mgr = SimPol('instance');
            else
                error('Simpol not loaded.');
            end
            
            importTempDir = tempname;
            mkdir(importTempDir);
            
            addpath(mgr.temporaryDirectory);
            
            tmpfilename = fullfile(importTempDir,...
                [simpol.utils.SLReq.reqSetName, '.slreqx']);
            
            % 1 - Close open req set
            % 2 - Delete file if exists
            % 3 - Reimport
            % 4 - Save
            % 5 - Update link file
            % 6 - Redirect existing links
            % 7 - Show/update link file
            
            % 1
            openReqSets = slreq.find('Type', 'ReqSet');
            if ~isempty(openReqSets)
                isSimpolImport = strcmp({openReqSets.Name}, simpol.utils.SLReq.reqSetName);
                if any(isSimpolImport)
                    oldSet = openReqSets(isSimpolImport);
                    oldSet.discard(); % Close without saving
                end
            end
            
            % 2
            if exist(tmpfilename, 'file')
                delete(tmpfilename);
            end
            
            % 3
            if ~exist(mgr.temporaryDirectory, 'file')
                mkdir(mgr.temporaryDirectory);
            end
            
            [num, name, reqset] = slreq.import('linktype_polarion',...
                'ReqSet', simpol.utils.SLReq.reqSetName,...
                'RichText', true);
            
            % 4
            reqset.save();
            
            % If no model names are given, we can stop here
            if nargin == 0
                slreq.open(reqset.Filename);
                return;
            end
            
            % Updating and showing the link file only works if the models
            % are open. So try to open them

            for i = 1:numel(modelnames)
                
                modelname = modelnames{i};
                
                try
                    open_system(modelname);
                    
                    % Unlock libraries, because otherwise requirement
                    % perspective cannot be entered
                    if Simulink.MDLInfo(modelname).IsLibrary
                        set_param('sysauto_lib', 'Lock', 'off');
                    end
                catch
                    continue;
                end
            
                % 5
                iReqSet = slreq.utils.getReqSet(reqset.Filename);
                iLinkSet = slreq.utils.getLinkSet(modelname);
                if isempty(iLinkSet) || ~isvalid(iLinkSet)
                    dummy = rmi('createEmpty');
                    rmi('set', modelname, dummy);
                    iLinkSet = slreq.utils.getLinkSet(modelname);
                    
                    % Remove dummy
                    reqs = rmi('get', modelname);
                    if numel(reqs) == 1
                        rmi('clearAll', modelname, 'noprompt');
                    else
                        rmi('set', modelname, reqs(1:end-1));
                    end
                end
                iLinkSet.addRegisteredRequirementSet(iReqSet)
                
                % 6
                % Update existing links
                iLinkSet.updateAllLinkDestinations();

                % 7
                % Enter Requirements perspective in the model
                appmgr = slreq.app.MainManager.getInstance;
                if ~appmgr.perspectiveManager.getStatus(get_param(modelname,'Handle'))
                    appmgr.togglePerspective(get_param(modelname,'Handle'),get_param(modelname,'Handle'));
                end

                % Force to register and show the ReqSet in the spreadsheet
                dasReqSet = appmgr.getDasObjFromDataObj(iReqSet);
                spObj = appmgr.getSpreadSheetObject(modelname);
                spObj.addReqLinkSet(dasReqSet)
                spObj.update();
            
            end
            
        end
    end
end

