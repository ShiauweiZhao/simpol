
% if exist(folderName, 'file') 
%     rmdir(folderName, 's');
% end

% copyfile('simpol', folderName);

% Set properties

try
    SimPol close

    rmpath(genpath('simpol'));
end

version = input('Version? ', 's');

folderName = ['SimPol-' version '_' datestr(datetime('now'), 'yyyymmdd')];
folderPath = fullfile(pwd, folderName);
mkdir(folderPath);
copyfile('simpol', folderPath);


fid = fopen(fullfile(folderPath, '+simpol', 'Manager.m'), 'r');
s = fread(fid, '*char')';
s = strrep(s, '##VERSION##', version);
s = strrep(s, '##BUILD##', datestr(now));
fclose(fid);

fid = fopen(fullfile(folderPath, '+simpol', 'Manager.m'), 'w');
fwrite(fid, s);
fclose(fid);

% Now add to path
addpath(genpath(folderPath));

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