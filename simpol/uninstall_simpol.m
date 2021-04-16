function uninstall_simpol

SimPol close

pathname = fileparts(which('uninstall_simpol'));

if isempty(pathname)
    error('Cannot find install directory!');
end

rmpath(genpath(pathname));
savepath();

sl_refresh_customizations;

% Register type
warning('off', 'Slvnv:rmi:unregisterLinktype:IgnoringUnregister');
try
    rmi('unregister', 'linktype_polarion');
catch
end
warning('on', 'Slvnv:rmi:unregisterLinktype:IgnoringUnregister');

sl_refresh_customizations;

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
fileID=fopen(path);
javpath_all=textscan(fileID,'%s\n');
fclose(fileID);

javpath_old=setdiff(javpath_all{1,1},wsclient_path);

if ~isempty(javpath_old)
    fileID=fopen(path,'w');
    fprintf(fileID,'%s\n',javpath_old{:});
    fclose(fileID);
else
    delete(path);
end

disp(['SimPol uninstalled from ''' pathname '''...']);
disp('Please remove the content of the folder manually. Due to locked ');
disp('Java libraries, a restart of MATLAB may be required before.');

end

