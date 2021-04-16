classdef Image
    %IMAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function img2 = addBorder(img1, t, c, stroke)
        % ADDBORDER draws a border around an image
        %
        %    NEWIMG = ADDBORDER(IMG, T, C, S) adds a border to the image IMG with
        %    thickness T, in pixels. C specifies the color, and should be in the
        %    same format as the image itself. STROKE is a string indicating the
        %    position of the border:
        %       'inner'  - border is added to the inside of the image. The dimensions
        %                  of OUT will be the same as IMG.
        %       'outer'  - the border sits completely outside of the image, and does
        %                  not obscure any portion of it.
        %       'center' - the border straddles the edges of the image.
        %
        % Example:
        %     load mandrill
        %     X2 = addborder(X, 20, 62, 'center');
        %     image(X2);
        %     colormap(map);
        %     axis off          
        %     axis image 

        %    Eric C. Johnson, 7-Aug-2008

            % Input data validation
            if nargin < 4
                error('MATLAB:addborder','ADDBORDER requires four inputs.');
            end

            if numel(c) ~= size(img1,3)
                error('MATLAB:addborder','C does not match the color format of IMG.');
            end

            % Ensure that C has the same datatype as the image itself.
            % Also, ensure that C is a "depth" vector, rather than a row or column
            % vector, in the event that C is a 3 element RGB vector.
            c = cast(c, class(img1));
            c = reshape(c,1,1,numel(c));

            % Compute the pixel size of the new image, and allocate a matrix for it.
            switch lower(stroke(1))
                case 'i'
                    img2 = simpol.utils.Image.addInnerStroke(img1, t, c);
                case 'o'
                    img2 = simpol.utils.Image.addOuterStroke(img1, t, c);
                case 'c'
                    img2 = addCenterStroke(img1, t, c);
                otherwise
                    error('MATLAB:addborder','Invalid value for ''stroke''.');
            end


        end


        % Helper functions for each stroke type
        function img2 = addInnerStroke(img1, t, c)

            [nr1, nc1, d] = size(img1);

            % Initially create a copy of IMG1
            img2 = img1;

            % Now fill the border elements of IMG2 with color C
            img2(:,1:t,:)           = repmat(c,[nr1 t 1]);
            img2(:,(nc1-t+1):nc1,:) = repmat(c,[nr1 t 1]);
            img2(1:t,:,:)           = repmat(c,[t nc1 1]);
            img2((nr1-t+1):nr1,:,:) = repmat(c,[t nc1 1]);

        end

        function img2 = addOuterStroke(img1, t, c)

            [nr1, nc1, d] = size(img1);

            % Add the border thicknesses to the total image size
            nr2 = nr1 + 2*t;
            nc2 = nc1 + 2*t;

            % Create an empty matrix, filled with the border color.
            img2 = repmat(c, [nr2 nc2 1]);

            % Copy IMG1 to the inner portion of the image.
            img2( (t+1):(nr2-t), (t+1):(nc2-t), : ) = img1;

        end

        function img2 = addCenterStroke(img1, t, c)

            % Add an inner and outer stroke of width T/2
            img2 = addInnerStroke(img1, floor(t/2), c);
            img2 = addOuterStroke(img2, ceil(t/2), c);    

        end
        
        function I = addHorizontalLine(I, y, c)
            I(y,:,1) = c(1);
            I(y,:,2) = c(2);
            I(y,:,3) = c(3);
        end
        
        function I = expand(I, y)
            I = [ones(y, size(I,2), 3)*255; I ];
        end
        
        function I = addText(I, s, fontsize, c, position)
            
            pt2in = 1/72;
            in2px = 96; % Windows worst case, Mac 72
            height = ceil(fontsize * pt2in * in2px) + 10;
            width = ceil(length(s) * (fontsize* pt2in * in2px));
            
            position(2) = height-position(2);
            
            % Create text
            hf = figure('color','white','units', 'pixels', 'Position',[0 0 width height], 'visible', 'off');
            image(ones(size(I)));
            set(gca,'units','pixels','position',[0, 0 width height],'visible','off');
            text('units','pixels','position',position,'fontsize',fontsize,'string', s, 'Interpreter', 'none');
            tim = getframe(hf);
            close(hf);
            
            % Crop
            tim = tim(min(size(tim,1), size(I,1)), min(size(tim,2), size(I,2)),:);
        
            tim2 = sum(tim.cdata,3);
            
            [i,j] = find(tim2 ~= (255*3));
            
            % r
            ind1 = sub2ind(size(tim.cdata), i, j, ones(size(i)));
            ind2 = sub2ind(size(I), i,j, ones(size(i)));
            I(ind2) = tim.cdata(ind1);
            
            % g
            ind1 = sub2ind(size(tim.cdata), i, j, ones(size(i))*2);
            ind2 = sub2ind(size(I), i,j, ones(size(i))*2);
            I(ind2) = tim.cdata(ind1);
            
            % b
            ind1 = sub2ind(size(tim.cdata), i, j, ones(size(i))*3);
            ind2 = sub2ind(size(I), i,j, ones(size(i))*3);
            I(ind2) = tim.cdata(ind1);
            
        end
        
        
    end
    
end

