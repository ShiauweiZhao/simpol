% if exist(folderName, 'file') 
%     rmdir(folderName, 's');
% end

% copyfile('simpol', folderName);

% Set properties

try
    SimPol close

    rmpath(genpath('simpol'));
end

% Protect all files
list = dir(fullfile(folderPath, '**/*.m'));

for i = 1:numel(list)
    fileInfo = list(i);
    
    if strcmp(fileInfo.name, 'start.m')
        continue;
    end
    
    if strcmp(fileInfo.folder, fullfile(folderPath, 'custom_rules'))
        continue;
    end
    
    pcode(fullfile(fileInfo.folder, fileInfo.name), '-inplace')
    delete(fullfile(fileInfo.folder, fileInfo.name));
end

rmpath(genpath(folderPath));

zip(folderName, folderPath);

rmdir(folderPath, 's');
