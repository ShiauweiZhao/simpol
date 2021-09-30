classdef Utils < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
   
    methods(Static)
        
        function i8_hash = encrypt(s)
            
            if isempty(s)
                i8_hash = 0;
                return;
            end
 
            c = clock;
            
            mgr = SimPol('instance');
            
            u8_key = uint8([112    c(1:3) 121   125   114 ...
                (typecast(double(mgr.hSimPolGUI.UIFigure), 'uint8') +...
                uint8([165   181   193    70   174   167    41    30]))   127]);
            sks = javax.crypto.spec.SecretKeySpec(u8_key , 'AES');
            cipher = javax.crypto.Cipher.getInstance('AES/ECB/PKCS5Padding', 'SunJCE');
            cipher.init(javax.crypto.Cipher.ENCRYPT_MODE, sks);
            i8_hash = cipher.doFinal(uint8(s));          
        end
        
        % -----------------------------------------------------------------
        
        function hash = stringHash(s)
            % stringHash Calculates the MD5 hash of a given string.
            % Returned is the hash as hex value (string).
            
            if isstring(s)
                s = char(s);
            end
            
            Engine = java.security.MessageDigest.getInstance('MD5');
            Engine.update(typecast(uint16(s(:)), 'uint8'));
            hash = sprintf('%.2x', double(typecast(Engine.digest, 'uint8')));
        end
        
        % -----------------------------------------------------------------
        
        function s = sid2ImageName(sid)
           s = [strrep(sid, ':', '-') '.png'];
        end
        
        % -----------------------------------------------------------------
        
        function pos = calcCenterDialogPosition(fg, widthDialog, heightDialog)
            
            xLeftWindow = fg.Position(1);
            yTopWindow = fg.Position(2);
            widthWindow = fg.Position(3);
            heightWindow = fg.Position(4);
            
            xLeftDialog = xLeftWindow + widthWindow/2 - widthDialog/2;
            yTopDialog = yTopWindow + heightWindow/2 - heightDialog/2;
            
            pos = [xLeftDialog, yTopDialog, widthDialog, heightDialog];
            
        end
        % -----------------------------------------------------------------
        
        function ref = getMatlabRefFromPath( filePath )
            % getMatlabRefFromPath derives the MATLAB function/class
            % reference from the input .m file path            
            
            isPkg = regexp( filePath, '(?:^|[/\\])\+(.+)\.m$', 'tokens' );
            isClass = regexp( filePath, '(?:^|[/\\])@(.+)[/\\](.+)\.m$', 'tokens' );
            if isempty( isPkg ) && isempty( isClass )
                [~,ref, ext] = fileparts(filePath);
                if ~any(strcmp(ext, simpol.adapter.RMIMatlabCodeAdapter.getTargetFileFilter()))
                    ref = {};
                end
            elseif ~isempty( isPkg ) && isempty( isClass )
                if length(isPkg) > 1 % Unexpected path string
                    ref = {};
                else
                    ref = regexprep( isPkg{1},'[/\\]\+', '.');
                    ref = string( regexprep( ref,'[/\\]', '.') );
                end
            elseif isempty( isPkg ) && ~isempty( isClass )
                ref = locExtractClassRef( isClass );
            else
                pkgToken = regexp( filePath, '(?:^|[/\\])\+(.+)[/\\]@', 'tokens' );
                pkgSubStr = regexprep( pkgToken{1},'[/\\]\+', '.');
                classSubStr = locExtractClassRef( isClass );
                ref = strcat( pkgSubStr, ".", classSubStr );
            end
        end
        
    end
end

function ref = locExtractClassRef( classTokens )
    if length(classTokens) > 1 % Unexpected path string
        ref = {};
    else
        if length(classTokens{1}) ~= 2 % Unexpected path string
            ref = {};
        elseif strcmp( classTokens{1}(1), classTokens{1}(2) )
            % Class constructor
            ref = classTokens{1}(1); 
        else
            % Class external function
            ref = strcat( classTokens{1}(1), "." , classTokens{1}(2) );
        end
    end
end

