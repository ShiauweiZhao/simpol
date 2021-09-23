classdef DirectLinkModel < simpol.linkmodel.AbstractLinkModel
   % DirectLinkModel In the direct linking approach, a hyperlink to the
   % MATLAB/Simulink item is added to the polarion work item (in the hyperlink section).
   % The hyperlink is resoled via RMI.
   % On the MATLAB/Simulink side, a hyperlink to the polarion work item (REST)
   % is added to the RMI link.
   %
   % Optionally, a screenshot can be saved in the Polarion work item.
    
    methods(Static)

        % -------------------------------------------------------------------------------------------
        
        function links = getLinks(polarionAdapter, item, jWorkItem) %#ok<INUSL>
            
            hyperlinks = jWorkItem.getHyperlinks();
            
            links = simpol.data.Link.empty(0, hyperlinks.length);    
            
            for i = 1:hyperlinks.length
                hyperlink = hyperlinks(i);
                uri = char(hyperlink.getUri());
                links(i) = simpol.data.Link(item, uri);  
                links(i).fromSide = simpol.SideType.POLARION;
                links(i).toItemId = uri; 
                links(i).unresolvedName = uri;
            end            
        end

        % -----------------------------------------------------------------
        
        function [b, workItemId] = addLinkToSimulink(polarionAdapter, rmiAdapter, workItemId, data)
            % addLinkToSimulink Mainly adding a hyperlink to the polarion
            % work item and adding a link.
            b = false;
            
            polarionAdapter.ensureOpenSession();
            
            % Get the work item
            jWorkItem = polarionAdapter.getWorkItem(...
                workItemId, {'description', 'attachments', 'hyperlinks'});
            
            if isempty(jWorkItem) || isempty(jWorkItem.getUri())
                return;
            end
            
            % Try to add a hyperlink
            bSuccessHyp = polarionAdapter.addHyperlink(jWorkItem, data.url);
            
            if ~polarionAdapter.settings.PushImage || ...
                    ~rmiAdapter.supportsSnapshot()
                
                polarionAdapter.updateCachedItem(workItemId);
                b = bSuccessHyp;
                return;
            end            
            
            % Try to update image. To avoid updating the image unnecessary,
            % the checksum of the image file is saved in the work item as
            % well.
            imgName = simpol.utils.Utils.stringHash(string(data.url)) + ".png";
            imgPath = fullfile(tempdir, imgName);
            rmiAdapter.makeSnapshot(...
                    data.mItemId, imgPath);
            
            checksum = lower(Simulink.getFileChecksum(imgPath));
            
            attachmentImgName = checksum + "_" + imgName;
            
            % Find image tag and compare checksums
            import javax.xml.parsers.DocumentBuilder;
            if ~isempty(jWorkItem.getDescription())
                doc = simpol.utils.XML.str2dom(...
                    char(jWorkItem.getDescription().getContent()),...
                    'fragment', true); % Parse fragment
            else
                doc = [];
            end

            % Check if image is up-to-date
            if ~isempty(doc)
                [~,imgTag] = polarionAdapter.findImageTag(doc, imgName);
                if isempty(imgTag)
                    bImgUpToDate = false;
                else
                    bImgUpToDate = contains(...
                        string(imgTag.getAttributes().getNamedItem('src').getNodeValue()),...
                        checksum);
                end
            else
                bImgUpToDate = false;
            end
            
            % Update attachment if required
            if ~bImgUpToDate
                bSuccessImg = polarionAdapter.addAttachment(...
                    jWorkItem, imgName, attachmentImgName, imgPath);
                % Reload work item since we need the id
                jWorkItem = polarionAdapter.getWorkItem(...
                    workItemId, {'description', 'attachments', 'hyperlinks'});
                
                % Update image tag in description
                bSuccessTag = polarionAdapter.addImageTag(...
                    jWorkItem, imgName);                
            else
                bSuccessImg = true;
                bSuccessTag = true;
            end            
            
            polarionAdapter.updateCachedItem(workItemId);
            
            b = bSuccessHyp && bSuccessImg && bSuccessTag;
            
        end

        % -----------------------------------------------------------------        
        
        function b = removeLinkToSimulink(polarionAdapter, rmiAdapter, link)
            % Identifer may be either 
            %  - the itemId
            %  - the URL or
            %  - just a index (one-based)
            
            workItemId = link.itemId;
        
            % Get current work item
            jWorkItem = polarionAdapter.getWorkItem(...
                workItemId, {'description', 'attachments', 'hyperlinks'});
            
           [b, ~] = polarionAdapter.removeHyperlink(jWorkItem, link.id);
            
            % If the link couldnt be removed or the link target is not
            % the Simulik adapter, do an early return. 
            if ~b || ~rmiAdapter.supportsSnapshot()
                polarionAdapter.updateCachedItem(workItemId);
                return;
            end
            
            imgName = simpol.utils.Utils.stringHash(link.toItemId) + ".png";

            b = b && polarionAdapter.removeImageTag(jWorkItem, imgName); 
            b = b && polarionAdapter.removeAttachment(jWorkItem, imgName);
            
            
            polarionAdapter.updateCachedItem(workItemId);   

        end        
    end
end

