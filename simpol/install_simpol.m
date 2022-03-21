function install_simpol

pathname = fileparts(mfilename("fullpath"));

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

if ~verLessThan('matlab','9.7')
    warning('off','MATLAB:ui:javacomponent:FunctionToBeRemoved')
end
if ~verLessThan('matlab','9.6')
   warning('off', 'MATLAB:mpath:nameNonexistentOrNotADirectory')
end
end