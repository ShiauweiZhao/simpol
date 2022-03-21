function instance = SimPol( mode )
% SimPol function manages the singleton instance of SimPol.
% Valid modes are
% - close
% - instance
% - test

% Test installation
%sl_refresh_customizations

init_wsclient_path;

if nargout == 0
    if isempty(what('+simpol')) || isempty(which('linktype_polarion'))
        warning('Please install before startup by calling install_simpol.');
        return;
    end
    
    warning('off', 'Slvnv:reqmgt:rmi:AlreadyRegistered');
    rmi('register', 'linktype_polarion');
    warning('on', 'Slvnv:reqmgt:rmi:AlreadyRegistered');
end

if nargin > 0
    mode = lower(mode);
end

rmi('httpLink')
h = findall(groot, 'Type', 'figure');
hApp = h(isprop(h, 'RunningAppInstance'));

% Closes all GUI instances
if nargin == 1 && strcmp(mode, 'close')
    if ~isempty(h)
        for i = 1:numel(hApp)
            if isa(hApp(i).RunningAppInstance, 'SimPolManager') ||...
                    isa(hApp(i).RunningAppInstance, 'SimPol_Settings') ||...
                    isa(hApp(i).RunningAppInstance, 'SimPol_Maintenance')
                close(hApp(i), 'force');
            end
        end
    end
    
elseif nargin == 1 && ~(strcmp(mode, 'test') || strcmp(mode, 'instance'))
    error(['SimPol ' mode ' command not supported'] );
    
else
    
    % ------------------------------
    % Check if instance exists
    
    if isempty(hApp)
        instanceExists= false;
    else
        h = hApp(arrayfun(@(x) isa(x.RunningAppInstance, 'SimPolManager'), hApp));
        
        if numel(h) > 1
            warning('Multiple instances of SimPol exist. Choosing first one');
            h = h(1);
        end
        
        if ~isempty(h) && isa(h.RunningAppInstance, 'SimPolManager')
            instanceExists = true;
        else
            instanceExists = false;
        end
    end
    
    % Return result of instance check if only testing
    if nargin == 1 && strcmp(mode, 'test')
        instance = instanceExists;
    else
        % Create new instance
        if instanceExists
            tmp = h.RunningAppInstance.mgr;
        else
            app = SimPolManager;
            tmp = app.mgr;
            h = app.UIFigure;
        end
        
        if nargin == 1 && strcmp(mode, 'instance') && nargout == 1
            instance = tmp;
        else
            h.Visible = 'on';
        end
    end
    
    
end

end

