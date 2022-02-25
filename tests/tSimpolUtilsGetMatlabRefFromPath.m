classdef tSimpolUtilsGetMatlabRefFromPath < matlab.unittest.TestCase
    
    % Verify simpol.adapter.RMIMatlabCodeAdapter.validateTarge extract
    % correctly the function/class reference from the file path

    properties (TestParameter)
        % extractBefore(pwd,filesep) returns the path prefix, which is used
        % to construct the testing paths.
        %   In Windows: "C:"
        %   In Unix: ""
        %   In mac: ""
        pathVsRef = {
            % absolute path (w/o space)
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "ProgramFiles", "matlab", "dummy.m") , "dummy" ]
                        
            % absolute path (w/ space)
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "Program Files", "matlab", "dummy.m") , "dummy" ]
            
            % local fun/class
            ["curDirFun.m", "curDirFun"]

            % class dir external fun
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "TMP", "@dummyDirClass", "extFun.m") , "dummyDirClass.extFun" ]

            % package
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "TMP", "+dummypkg", "dummyPkgFun.m") , "dummypkg.dummyPkgFun" ]

            % subpackage
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "TMP", "+dummypkg", "+dummysubpkg", "dummySubPkgFun.m") , "dummypkg.dummysubpkg.dummySubPkgFun" ]

            % + in the middle of filename
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "matlab", "bad+folder", "dummy.m") , "dummy" ]

            % class in the package
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "TMP", "+simpol", "@Manager", "Manager.m") , "simpol.Manager" ]

            % class in the subpackage
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "TMP", "+simpol", "+adapter", "@RMIMatlabCodeAdapter", "RMIMatlabCodeAdapter.m") , "simpol.adapter.RMIMatlabCodeAdapter" ]

            % class dir external fun in the package
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "TMP", "+simpol", "@Manager", "addLink.m") , "simpol.Manager.addLink" ]

            % wrong extension
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "matlab", "dummy.mat") , "" ]

            % @ in the middle of filename
            [ fullfile( extractBefore(pwd,filesep), filesep, ...
                        "TMP", "128471@3242", "dummy.m") , "dummy" ]
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
