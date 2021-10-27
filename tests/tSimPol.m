%% Test Class Definition
classdef tSimPol < matlab.unittest.TestCase
        
    properties
        polarionWorkitemType = 'systemRequirement';
    end
    
    methods(TestClassSetup)
        function setup(tc)
            import matlab.unittest.fixtures.*;
            tc.applyFixture( PathFixture( pwd,'IncludingSubfolders',true ) );
            tc.applyFixture(WorkingFolderFixture('WithSuffix', 'SIMPOL_TEST'));
            assignin('base', 'tenvpath', pwd);
        end

    end
    
    methods
        
        function settings = getSettings(tc)
            settings = simpol.utils.AllocConfig();
            settings.ServerURL = 'https://polarion.fsd.ed.tum.de/polarion/';
            settings.ProjectID = 'Playground';
            settings.QueryString = ['type:' tc.polarionWorkitemType];
            settings.BaselineRevision = '';
            settings.PushImage = true;  
        end
        
        function getPolarionAdapter(~, linkModelName, settings)

            % Setup polarion adapter
            pb = simpol.adapter.PolarionAdapter(h, linkModelName);
            pb.setServerURL(settings.ServerURL);
            pb.setProjectID(settings.ProjectID);
            pb.setBaseQuery(settings.QueryString);
            pb.setBaseline(settings.BaselineRevision);
            pb.setCredentials(getpref('SimPol', 'UserName'), getpref('SimPol', 'UserPassword'));
            pb.updateServices();
            pb.ensureOpenSession();               
            
        end
        
        function modelname = createTestModel(~)
            
            [~, name] = fileparts(tempname);
            
            modelname = ['model_' name];
            
            bdclose all
            copyfile(which('dummyModel'), fullfile(pwd,  [modelname '.slx']));              
        end
        
        function setupManager(~, mgr, filepath, modelname)
            mgr.setAllocationFile(filepath);
            
             % Update settings and services
            mgr.updateSettings();
            %mgr.polarionBridge.updateServices();
            mgr.polarionAdapter.updateServices();
            
             % Load Model
            load_system(modelname);
            
            mgr.matlabAdapter.detectTargets();
            mgr.matlabAdapter.updateCache();           
            
        end        
        
        function [id, name] = createTestWorkItem(tc, pb)
                    % Create a new requirement item
            [~, name] = fileparts(tempname);
            
            pb.ensureOpenSession();
            
            jWorkItem = pb.toWorkItem(tc.polarionWorkitemType, 'title', name, 'description',name);
            id = pb.createWorkItem(jWorkItem);
        end
    end
    
    methods(TestClassTeardown)
        function test_shutdown(~)
            SimPol('close')
        end        
    end
    
end

