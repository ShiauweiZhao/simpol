classdef SurrogateLinkModel < simpol.linkmodel.AbstractLinkModel
    % SurrogateLinkModel In this approach, the the Polarion work item links
    % to a surrogate, automatically generated work item in Polarion, which
    % holds the hyperlinkt to the RMI item on the MATLAB/Simulink side.
    
    methods(Static)     
        
        function links = getLinks(polarionAdapter, item, jWorkItem)
            links = simpol.data.Link.empty(0,1);
            
            % Get internal Polarion links and select those relevant for the
            % given adapter.
            jDrvWorkItems = jWorkItem.getLinkedWorkItemsDerived();
            
            for i = 1:numel(jDrvWorkItems)
                
                jWiLink = jDrvWorkItems(i);
                
                if strcmp(char(jWiLink.getRole().getId()),...
                        polarionAdapter.settings.SurrogateLinkRole)
                    
                    jSurrogateWorkItem = polarionAdapter.getWorkItem(...
                        char(jWiLink.getWorkItemURI()), {'title','type', 'hyperlinks'});
                    
                    % skip if work item type is not same as specified in
                    % allocation file. Different work items with same roles
                    % can exist so checking based on type
                    if ~strcmp(char(jSurrogateWorkItem.getType().getId()),...
                            polarionAdapter.settings.SurrogateWorkItemType)
                        continue
                    end
                    
                    hyperlinks = jSurrogateWorkItem.getHyperlinks();
                    if hyperlinks.length ~= 1
                        polarionAdapter.notifyError("Invalid surrogate work item:" + ...
                         string(jWiLink.getWorkItemURI()) + ...
                         ". Exactly 1 hyperlink expected, but found " + hyperlinks.length + ".");
                        continue;
                    end
                    
                    
                    link = simpol.data.Link(item, char(hyperlinks(1).getUri));                    
                    link.fromSide = simpol.SideType.POLARION;
                    link.toItemId = char(hyperlinks(1).getUri());                                      
                    link.unresolvedName = char(jSurrogateWorkItem.getTitle());
                    link.suspected = logical(jWiLink.getSuspect == java.lang.Boolean(true));
                    links = [links link]; %#ok<AGROW>

                end
            end
        end
        
        % -----------------------------------------------------------------
        
        function b = addLinkToSimulink(polarionAdapter, rmiAdapter, workItemId, data)
            
            b = false;
            
            % Check if a work item or create a new one
            % -------------------------------------------------------------
            
            surrogateWorkItemUri = ...
                simpol.linkmodel.SurrogateLinkModel.getSurrogateItemUri(...
                polarionAdapter, data.mItemId);
            
            % If it is not a work item, create a surrogate work item
            if isempty(surrogateWorkItemUri)
                
                [surrogateWorkItemId, surrogateWorkItemUri ] =...
                    polarionAdapter.createWorkItem(...
                        polarionAdapter.toWorkItem(...
                            polarionAdapter.settings.SurrogateWorkItemType,...
                            'title', data.mItemId));
                
                if isempty(surrogateWorkItemUri) || isempty(surrogateWorkItemId)
                    b = false;
                    return;
                end
                
            end
                        
            % Update the surrogate item
            % -------------------------------------------------------------
            
            jSurrogateWorkItem = polarionAdapter.getWorkItem(...
                surrogateWorkItemUri, {'description', 'attachments', 'hyperlinks'});
            
            bSuccessHyp = polarionAdapter.addHyperlink(jSurrogateWorkItem, data.url);
            
            % for test cases, add path in description
            if strcmpi(rmiAdapter.settings.TargetType, 'simpol.adapter.RMISimulinkTestAdapter')
                bSuccessDesc = polarionAdapter.addDescription(...
                    jSurrogateWorkItem, data.description);
            end
            
            if polarionAdapter.settings.PushImage && ...
                    rmiAdapter.supportsSnapshot()

                % Get image
                imgName = simpol.utils.Utils.stringHash(data.url) + ".png";
                imgPath = fullfile(tempdir, imgName);
                rmiAdapter.makeSnapshot(...
                    data.mItemId, imgPath);
                
                % Check if image is up-to-date
                checksum = lower(Simulink.getFileChecksum(imgPath));
                
                attachmentImgName = checksum + "_" + imgName;
                
                % Find image tag and compare checksums
                import javax.xml.parsers.DocumentBuilder;
                if ~isempty(jSurrogateWorkItem.getDescription())
                    doc = simpol.utils.XML.str2dom(...
                        char(jSurrogateWorkItem.getDescription().getContent()),...
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
                        jSurrogateWorkItem, imgName, attachmentImgName, imgPath);
                    
                    % Reload work item since we need the id
                    jSurrogateWorkItem = polarionAdapter.getWorkItem(...
                        surrogateWorkItemUri, {'description', 'attachments'});
                    
                     % Update image tag in description
                    bSuccessTag = polarionAdapter.addImageTag(...
                        jSurrogateWorkItem, imgName);  
                else
                    bSuccessImg = true;
                    bSuccessTag = true;
                end
    
            end
            
            % Add linkn from requirement work item to surrogate work item
            % -------------------------------------------------------------
            
            bSuccessLink = polarionAdapter.addWorkItemLink(...
                surrogateWorkItemUri,...
                workItemId,...
                polarionAdapter.settings.SurrogateLinkRole);
            
            polarionAdapter.updateCachedItem(workItemId);
            
            b = true;              
            
        end
        
        % -----------------------------------------------------------------
        
        function b = removeLinkToSimulink(polarionAdapter, rmiAdapter, link) %#ok<INUSL>
            % removeLinkToSimulink Removes the link from the polarion work
            % item.
            % Note: This function does not delete the surrogate item, since
            % Polarion does not support deleting work items via webservice API.
            
            b = false;
                        
            workItemId = link.itemId;
            
            % Check if a work item
            surrogateWorkItemUri =...
                simpol.linkmodel.SurrogateLinkModel.getSurrogateItemUri(...
                polarionAdapter, link.unresolvedName);
            
            if ~isempty(surrogateWorkItemUri)
                polarionAdapter.removeWorkItemLink(surrogateWorkItemUri, workItemId,...
                    polarionAdapter.settings.SurrogateLinkRole);
            end
  
            polarionAdapter.updateCachedItem(workItemId);
            
            b = true;
        end
    end
    
    methods(Static, Access=private)
        
        function s = getSurrogateItemUri(polarionAdapter, mItemId)
            
            mItemId = convertStringsToChars(mItemId);
            
            query = ['title:' strrep(mItemId, ':', '\:')...
                ' AND type:' polarionAdapter.settings.SurrogateWorkItemType];
            
            uris = polarionAdapter.trackerService.queryWorkItemUris(query, 'title');
            
            if isempty(uris) || (uris.length == 0)
                s = [];
            elseif uris.length > 1
                error(['Surrogate work item "' mItemId '" exists more than once with type "'...
                    polarionAdapter.settings.SurrogateWorkItemType '". Delete duplicate instances manually in Polarion before continuing linking. '...
                    'Query "' query '".' ]);
            else
                s = char(uris(1));
            end
        end
        
    end
    
end

