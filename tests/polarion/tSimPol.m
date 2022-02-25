%% Test Class Definition
classdef tSimPol < matlab.unittest.TestCase
        
    properties (TestParameter)
          parameters = {'URL','Project','username','password', 'type'};
    end
    
    methods(TestClassSetup)
        function setup(tc)
            import matlab.unittest.fixtures.*;
            tc.applyFixture( PathFixture( pwd,'IncludingSubfolders',true ) );
            % Adding required models for the test to the directory temporarily
            x = pwd;x = strrep(x,'\polarion','');
            tc.applyFixture( PathFixture(x, 'IncludingSubfolders',true ) );
            clear x;
            tc.applyFixture(WorkingFolderFixture('WithSuffix', 'SIMPOL_TEST'));
            assignin('base', 'tenvpath', pwd);
        end

    end
    
    methods
        
        function settings = getSettings(tc, parameters)
            settings = simpol.utils.AllocConfig();
            settings.ServerURL = parameters{1};
            settings.ProjectID = parameters{2};
            settings.QueryString = ['type:' parameters{5}];
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
            pb.setCredentials(parameters{3}, parameters{4});
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
            mgr.polarionAdapter.updateServices();
            
             % Load Model
            load_system(modelname);
            
            mgr.matlabAdapter.detectTargets();
            mgr.matlabAdapter.updateCache();           
            
        end        
        
        function [id, name] = createTestWorkItem(tc, pb, parameters)
                    % Create a new requirement item
            [~, name] = fileparts(tempname);
            pb.setCredentials(parameters{3}, parameters{4});
            
            pb.ensureOpenSession();
            
            jWorkItem = pb.toWorkItem(parameters{5}, 'title', name, 'description',name);
            id = pb.createWorkItem(jWorkItem);
        end
    end
    
    methods(TestClassTeardown)
        function test_shutdown(~)
            SimPol('close')
        end        
    end
    
end

