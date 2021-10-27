classdef tSimpolUtilsGetMatlabRefFromPath_WIN< matlab.unittest.TestCase
    
    % Verify simpol.adapter.RMIMatlabCodeAdapter.validateTarge extract
    % correctly the function/class reference from the file path
    
    properties (TestParameter)
        pathVsRef = {
            % win
            ["C:\Program Files\MATLAB\R2021a\toolbox\matlab\general\pwd.m", "pwd"]
            % local fun/class
            ["curDirFun.m", "curDirFun"]
            % class dir external fun
            ["C:\TMP\@dummyDirClass\extFun.m", "dummyDirClass.extFun"]
            % package
            ["C:\TMP\+dummypkg\dummyPkgFun.m", "dummypkg.dummyPkgFun"]
            % subpackage
            ["C:\TMP\+dummypkg\+dummysubpkg\dummySubPkgFun.m", "dummypkg.dummysubpkg.dummySubPkgFun"]
            % class in the package
            ["D:\TMP\+simpol\@Manager\Manager.m", "simpol.Manager"]
            % class in the subpackage
            ["D:\TMP\+simpol\+adapter\@RMIMatlabCodeAdapter\RMIMatlabCodeAdapter.m", "simpol.adapter.RMIMatlabCodeAdapter"]
            % class dir external fun in the package
            ["C:\TMP\+simpol\@Manager\addLink.m", "simpol.Manager.addLink"]
            % wrong extension
            ["C:\Program Files\MATLAB\R2021a\toolbox\matlab\general\pwd.mat", ""]
            % @ in the middle of filename
            ["C:\TMP\128471@3242\pwd.m", "pwd"]
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
            
            testcase.assumeTrue( ispc,...
                "Test runs only on a Windows platform." );        
            
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