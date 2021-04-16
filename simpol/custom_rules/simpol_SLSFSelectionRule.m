function sids = simpol_SLSFSelectionRule(modelname)

% Ensure that system is available and loaded
if ~exist(modelname, 'file')
    sids = [];
    return;
end
load_system(modelname);
    

% SIMULINK
% -------------------------------------------------------------------------

% Get all blocks
% Exclude commented blocks - they shall not have a link
% Exclude all items in library, since they shall be linked in the Simulink
% library.
blockPaths = find_system(modelname,...
    'FollowLinks', 'off', 'LookUnderMasks', 'all', 'IncludeCommented', false);

slsids = Simulink.ID.getSID(blockPaths);

% Blocks, which are in a library or in a Stateflow chart, have a
% two-semicolon-ID. The find_system above does not go into libraries, but
% since "LookUnderMasks" is activated, also pseudo blocks behind Stateflow
% charts are found. These must be removed, since they are not visible
% graphical elements.
slsids = slsids(cellfun(@(x) length(x), strfind(slsids, ':'))<=1);

% STATEFLOW
% -------------------------------------------------------------------------

% Excluded commented
additionalParams = {'IsExplicitlyCommented', false,...
                    'IsImplicitlyCommented', false};

rt = sfroot;
sfbd = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', modelname);

sfcharts = sfbd.find('-isa', 'Stateflow.Chart');

sfsids = [];

for iChart = 1:numel(sfcharts)

    % If a chart is commented from Simulink, we cannot see this in the
    % stateflow properties. We have to exclude these subsystems manually.
    % The only way to also capture charts, which are not directly
    % communted, but the any upper container, is checking what find_system
    % returned.
    if  ~ismember(slsids, Simulink.ID.getSID(sfcharts(iChart)))
        continue;
    end
    
    % These are the linkable Stateflow primitives
    os = sfcharts(iChart).find(...
        '-isa', 'Stateflow.State', additionalParams{:}, '-or',...
        '-isa', 'Stateflow.Transition', additionalParams{:}, '-or',...
        '-isa', 'Stateflow.Box', additionalParams{:}, '-or',...
        '-isa', 'Stateflow.Function', additionalParams{:});

    % No batch way known
    tmp = cell(numel(os),1);
    for iObject = 1:numel(os)
        tmp{iObject} = Simulink.ID.getSID(os(iObject));
    end
    sfsids = [sfsids; tmp];

end

% Annotation id
annHnd=find_system(modelname,'FindAll','on','type','annotation');
saids=Simulink.ID.getSID(annHnd);

sids = [slsids; sfsids; saids];


end