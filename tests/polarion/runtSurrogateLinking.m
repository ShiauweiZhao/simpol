function results = runtSurrogateLinking(URL, Project, User, Pass)
%% This test needs to be run on the Polarion server

%This function runs the Direct Linking test file and passes the
%parameters to the test file in the manner of 
%runtSurrogateLinking(URL of the server, Project name, Username, Password). 
%All the parameters passed here in char data type

import matlab.unittest.parameters.Parameter
import matlab.unittest.TestSuite
A = {URL, Project, User, Pass, 'systemRequirement'};

import matlab.unittest.parameters.Parameter
newData = {A};
param = Parameter.fromData('parameters',newData);

suite2 = TestSuite.fromClass(?tSurrogateLinking,'ExternalParameters',param);
results = suite2.run;
end