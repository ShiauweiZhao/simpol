%% Test Class Definition
classdef tDirectLinking < tSimPol
    
    methods(Test)
 
        
        function test_save_allocfile(tc)
            
            % Create test model
            modelname = tc.createTestModel();            
            
            settings = tc.getSettings();
            settings.LinkModel = 'Direct Linking';
            settings.TargetType = 'simpol.adapter.RMISimulinkAdapter';
            settings.Targets = {modelname};
            
            % Check if allocation file is stored correctly
            mgr = SimPol('instance');
            filepath = fullfile(pwd, 'myallocation.spa');
            mgr.setAllocationFile(filepath);
            settings.save( filepath );
            tc.verifyTrue(exist(filepath, 'file') > 0);           
            
            tc.setupManager(mgr, filepath, modelname);
            
            % Create a test requirement
            [pItemId1, name1] = tc.createTestWorkItem(mgr.polarionAdapter);
            [pItemId2, name2] = tc.createTestWorkItem(mgr.polarionAdapter);
            mgr.polarionAdapter.updateCache();
            
            % Get test rmi items
            rItemId1 = [modelname ':13'];
            rItemId2 = [modelname ':5'];
            
            % TEST GENERAL LINKING (WITH IMAGE)
            % P1 <------> R1
            %    <------> R2
            % P2 <------> 
           
            tc.linkIt(mgr, pItemId1, rItemId1, true);           
            tc.linkIt(mgr, pItemId1, rItemId2, true);
            tc.linkIt(mgr, pItemId2, rItemId2, true);
            
            tc.removeIt(mgr, pItemId1, rItemId1, simpol.SideType.POLARION, true);
            jWorkItem1 = tc.removeIt(mgr, pItemId1, rItemId2, simpol.SideType.MATLAB,true);
            jWorkItem2 = tc.removeIt(mgr, pItemId2, rItemId2, simpol.SideType.POLARION,true);
            
            % Check that content is not replaced
            tc.verifyEqual(char(jWorkItem1.getDescription().getContent()), [name1, '<br/><br/>']);            
            tc.verifyEqual(char(jWorkItem2.getDescription().getContent()), [name2, '<br/>']);
            
            % TEST GENERAL LINKING (WITHOUT IMAGE)
            s = mgr.settings;
            s.PushImage = false;
            s.save( filepath );
            tc.setupManager(mgr, filepath, modelname);
            mgr.polarionAdapter.updateCache();
            
            % Make a link with image
            tc.linkIt(mgr, pItemId1, rItemId1, false);
            
            % Remove link
            tc.removeIt(mgr, pItemId1, rItemId1, simpol.SideType.POLARION, false);
            
            % Check that content is not replaced
            tc.verifyEqual(char(jWorkItem1.getDescription().getContent()), [name1, '<br/><br/>']);            
            tc.verifyEqual(char(jWorkItem2.getDescription().getContent()), [name2, '<br/>']);
        
            bdclose all
            delete(mgr);
            
        end
        

    end
    
    
    methods
        
        
        function jWorkItem = linkIt(tc, mgr, pItemId, rItemId, pushImage) 
            
            % Old values
            jWorkItemOld = mgr.polarionAdapter.getWorkItem(pItemId);
            numRLinksOld = numel(rmi('get', rItemId));
            numHyperlinksOld = numel(jWorkItemOld.getHyperlinks());
            numAttachmentsOld = numel(jWorkItemOld.getAttachments());
            doc = simpol.utils.XML.str2dom(char(jWorkItemOld.getDescription().getContent()), 'fragment', true);
            [~, ~, nTags] = findImageTag(mgr.polarionAdapter, doc, '');
            numTagsOld = nTags;
            
            mgr.addLink(pItemId, rItemId);
            
            % Verify existance of link in simulink
            reqlinks = rmi('get', rItemId);
            tc.verifyEqual(numel(reqlinks), numRLinksOld+1);
            tc.verifyTrue(strcmp(reqlinks(end).reqsys, 'linktype_polarion'));
            
            % Check counter side
            jWorkItem = mgr.polarionAdapter.getWorkItem(pItemId);
            
            hyperlinks = jWorkItem.getHyperlinks();
            attachments = jWorkItem.getAttachments();            

            % Check hyperlink
            tc.verifyEqual(numel(hyperlinks),numHyperlinksOld+1);
            tc.verifyEqual(char(hyperlinks(end).getUri()), mgr.matlabAdapter.getNavURL(rItemId));
                
            if pushImage 
                %MY TRIAL
                if strcmpi(mgr.settings.TargetType,"simpol.adapter.RMISimulinkTestAdapter")
                    description= h.matlabAdapter.getCachedItem(rItemId).optional('path');
                else
                    description = "";
                end
                data = struct("url", string(mgr.matlabAdapter.getNavURL(char(rItemId))),...
                    "mItemId", rItemId,...
                    "description", string(description),...
                    "imagePath", "",...
                    "imageChecksum", "");
                imgName = simpol.utils.Utils.stringHash(string(data.url)) + ".png";
                imgPath = fullfile(tempdir, imgName);
                checksum = lower(Simulink.getFileChecksum(imgPath));
                attachmentImgName = checksum + "_" + imgName;
                imgName = char(attachmentImgName);
                %END OF MY TRIAL
                
                % Check attachment
                %imgName = [strrep(rItemId, ':', '-') '.png'];
                tc.verifyEqual(numel(attachments),numAttachmentsOld+1);
                tc.verifyEqual(char(attachments(end).getFileName()), imgName);
                % Check embedded image
                doc = simpol.utils.XML.str2dom(char(jWorkItem.getDescription().getContent()), 'fragment', true);
                [idxTag, imgTag, nTags] = findImageTag(mgr.polarionAdapter, doc, imgName);
                tc.verifyEqual(idxTag, numTagsOld+1)
                tc.verifyTrue(~isempty(imgTag));
                tc.verifyEqual(nTags, numTagsOld+1);
            else
                % Check attachment
                tc.verifyEqual(numel(attachments),numTagsOld);
                % Check embedded image
                doc = simpol.utils.XML.str2dom(char(jWorkItem.getDescription().getContent()), 'fragment', true);
                [idxTag, imgTag, nTags] = findImageTag(mgr.polarionAdapter, doc, '');
                tc.verifyEqual(nTags, numTagsOld);                
            end

        end
        
        function jWorkItem = removeIt(tc, mgr, pItemId, rItemId, side, pushImage)
            
            % Old values
            mgr.updateLinkTable
            jWorkItemOld = mgr.polarionAdapter.getWorkItem(pItemId);
            numRLinksOld = numel(rmi('get', rItemId));
            numHyperlinksOld = numel(jWorkItemOld.getHyperlinks());
            numAttachmentsOld = numel(jWorkItemOld.getAttachments());
            doc = simpol.utils.XML.str2dom(char(jWorkItemOld.getDescription().getContent()), 'fragment', true);
            [~, ~, nTags] = findImageTag(mgr.polarionAdapter, doc, '');
            numTagsOld = nTags;
            
            % Remove links
            %%%%%%%%%%%%%%%%
            if strcmp(side, 'POLARION')
                linkIdd = pItemId + "|" + mgr.matlabAdapter.getNavURL(rItemId);
            else
                for i=1:height(mgr.linkTable.tableMatlabLinks)
                if isequal(mgr.linkTable.tableMatlabLinks.ResolvedItemId(i), string(pItemId))...
                        && isequal(mgr.linkTable.tableMatlabLinks{i,1}.itemId, string(rItemId))
                   linkIdd =  mgr.linkTable.tableMatlabLinks{i,1}.id;
                   break;
                end
                end
            end
            %%%%%%%%%%%%%%%%
            %idd = mgr.linkTable.linkPairs{1,1}.id;
           
            
            
     
                mgr.removeLink(side, linkIdd);

            %%%%%%%%%%%%%%%%%%
%             if strcmp(side, 'polarion')
%                 mgr.removeLink(pItemId, rItemId, side);
%             else
%                 mgr.removeLink(rItemId, pItemId, side);
%             end
            
            % Verify existance of link in simulink
            reqlinks = rmi('get', rItemId);
            tc.verifyEqual(numel(reqlinks), numRLinksOld-1);
            
            % Check counter side
            jWorkItem = mgr.polarionAdapter.getWorkItem(pItemId);
            hyperlinks = jWorkItem.getHyperlinks();
            attachments = jWorkItem.getAttachments();
            % Check hyperlink
            tc.verifyEqual(numel(hyperlinks),numHyperlinksOld-1);
            if pushImage
                % Check attachment
                imgName = [strrep(rItemId, ':', '-') '.png'];
                tc.verifyEqual(numel(attachments),numAttachmentsOld-1);
                % Check embedded image
                doc = simpol.utils.XML.str2dom(char(jWorkItem.getDescription().getContent()), 'fragment', true);
                [idxTag, imgTag, nTags] = findImageTag(mgr.polarionAdapter, doc, imgName);
                tc.verifyEqual(nTags, numTagsOld-1);
            else
                tc.verifyEqual(numel(attachments),numAttachmentsOld);
                tc.verifyEqual(nTags, numTagsOld);
            end
            
        end
    end
end

