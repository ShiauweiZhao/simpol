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

disp(['SimPol uninstalled from ''' pathname '''...']);
disp('Please remove the content of the folder manually. Due to locked ');
disp('Java libraries, a restart of MATLAB may be required before.');

end

