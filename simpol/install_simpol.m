function install_simpol

pathname = fileparts(which('install_simpol'));

if isempty(pathname)
    error('Cannot find install directory! Are you in the directory?');
end

addpath(genpath(pathname));
savepath();

disp(['SimPol initialized from ''' pathname '''...']);

% Register type
warning('off', 'Slvnv:rmi:unregisterLinktype:IgnoringUnregister');
try
    rmi('unregister', 'linktype_polarion');
catch
end
warning('on', 'Slvnv:rmi:unregisterLinktype:IgnoringUnregister');

warning('off', 'Slvnv:reqmgt:rmi:AlreadyRegistered');
rmi('register', 'linktype_polarion');
warning('on', 'Slvnv:reqmgt:rmi:AlreadyRegistered');

% Delete history
historyFile = fullfile(prefdir, 'RMIHist.mat');
if exist(historyFile, 'file')
    delete(historyFile);
end

% Add java class path
wsclient_path={
    '/wsclient/wsclient.jar', ...
    '/wsclient/axis-patch.jar', ...
    '/wsclient/lib/axis.jar', ...
    '/wsclient/lib/commons-codec-1.4.jar', ...
    '/wsclient/lib/commons-discovery-0.2.jar', ...
    '/wsclient/lib/commons-httpclient-3.1.jar', ...
    '/wsclient/lib/commons-logging-1.0.4.jar', ...
    '/wsclient/lib/jaxrpc.jar', ...
    '/wsclient/lib/saaj.jar', ...
    '/wsclient/lib/wsdl4j-1.5.1.jar'};
wsclient_path = (strcat(fullfile(pathname, '3rdparty'), wsclient_path))';
path=fullfile(prefdir,'javaclasspath.txt');
if exist(path)>0
    fileID = fopen(path,'a');
else
    fileID = fopen(path,'w');
end
fprintf(fileID,'%s\n',wsclient_path{:});
fclose(fileID);
disp('Restart your MATLAB.');

if ~verLessThan('matlab','9.7')
    warning('off','MATLAB:ui:javacomponent:FunctionToBeRemoved')
end
if ~verLessThan('matlab','9.6')
   warning('off', 'MATLAB:mpath:nameNonexistentOrNotADirectory')
end
end