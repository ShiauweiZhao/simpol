installPath = fileparts(mfilename('fullpath'));

addpath(genpath(installPath));

wsclient_path={
    '/wsclient/wsclient.jar', ...
    '/wsclient/axis-patch.jar', ...
    '/wsclient/lib/axis.jar', ...
    '/wsclient/lib/commons-discovery-0.2.jar', ...
    '/wsclient/lib/commons-httpclient-3.1.patched.jar', ...
    '/wsclient/lib/commons-logging-1.0.4.jar', ...
    '/wsclient/lib/jaxrpc.jar', ...
    '/wsclient/lib/saaj.jar', ...
    '/wsclient/lib/wsdl4j-1.5.1.jar'};
wsclient_path = strcat(fullfile(installPath, '3rdparty'), wsclient_path);

javaaddpath(wsclient_path);

setpref('SimPol', 'Debug', true)
disp('Set to debug mode...');

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