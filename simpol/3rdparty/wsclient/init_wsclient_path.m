function init_wsclient_path()

    % only need to add JAR files if not loaded yet, this prevents warnings when the libraries are defined twice
    if exist('com.polarion.alm.ws.client.WebServiceFactory', 'class')
        return
    end

    thisFolder = fileparts(mfilename('fullpath'));
    loadedJarFiles = regexprep(javaclasspath('-all'), "^.*[/\\]", "");
    neededJarFiles = transpose(dir(fullfile(thisFolder, '*.jar')));

    for jarFile = neededJarFiles
        if not(ismember(jarFile.name, loadedJarFiles))
            javaaddpath(fullfile(jarFile.folder, jarFile.name));
        end
    end
end
