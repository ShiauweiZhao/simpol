classdef tSimpolUtilsGetMatlabRefFromPath_LIN< matlab.unittest.TestCase
    
    % Verify simpol.adapter.RMIMatlabCodeAdapter.validateTarge extract
    % correctly the function/class reference from the file path
    
    properties (TestParameter)
        pathVsRef = {
            % linux
            ["/mw/snapshot/build/matlab/toolbox/matlab/general/pwd.m", "pwd"]
            % local fun/class
            ["curDirFun.m", "curDirFun"]
            % class dir
            ["/mw/@dummyDirClass/dummyDirClass.m", "dummyDirClass"]
            % + in the middle of filename
            ["/mw/snapshot/build/matlab/toolbox/matlab/bad+folder/pwd.m", "pwd"]
            }
    end
    
    methods(TestClassSetup)
        % None
    end
    
    methods(TestMethodSetup)
        % None
    end
    
    methods(TestMethodTeardown)
        % None
    end
    
    methods(Test)
        
        function correctPath( testcase, pathVsRef )
            
            testcase.assumeTrue( isunix,...
                "Test runs only on a Linux platform." );        
            
            if ~strcmp( pathVsRef(2), "")
                testcase.verifyEqual( ...
                    simpol.utils.Utils.getMatlabRefFromPath( ...
                    pathVsRef(1) ) , pathVsRef(2) );
            else
                testcase.verifyEmpty( ...
                    simpol.utils.Utils.getMatlabRefFromPath( ...
                    pathVsRef(1) ));
            end
        end
    end
end