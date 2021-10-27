%% Test Class Definition
classdef tSurrogateLinking < tSimPol
        
    methods(Test)
     
        
        function test_save_allocfile(tc, parameters)

            
            % Create test model
            modelname = tc.createTestModel();              
            
            settings = tc.getSettings(parameters);
            settings.LinkModel = 'Surrogate Linking';
            settings.SurrogateWorkItemType = 'slDesignModel';
            settings.SurrogateLinkRole = 'implements';
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
            [pItemId1, name1] = tc.createTestWorkItem(mgr.polarionAdapter, parameters);
            [pItemId2, name2] = tc.createTestWorkItem(mgr.polarionAdapter, parameters);
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
            tc.verifyEqual(char(jWorkItem1.getDescription().getContent()), name1);            
            tc.verifyEqual(char(jWorkItem2.getDescription().getContent()), name2);
            
%             % TEST GENERAL LINKING (WITHOUT IMAGE)
%             s = mgr.settings;
%             s.PushImage = false;
%             mgr.saveSettings(s);
%             tc.setupManager(mgr, filepath, modelname);
%             mgr.polarionAdapter.updateCache();
%             
%             % Make a link with image
%             tc.linkIt(mgr, pItemId1, rItemId1, false);
%             
%             % Remove link
%             tc.removeIt(mgr, pItemId1, rItemId1, 'polarion', false);
%             
%             % Check that content is not replaced
%             tc.verifyEqual(char(jWorkItem1.getDescription().getContent()), name1);            
%             tc.verifyEqual(char(jWorkItem2.getDescription().getContent()), name2);
            
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
            numDerivedLinksOld = numel(jWorkItemOld.getLinkedWorkItemsDerived());
            numAttachmentsOld = numel(jWorkItemOld.getAttachments());
            
            mgr.addLink(pItemId, rItemId);
            
            % Verify existance of link in simulink
            reqlinks = rmi('get', rItemId);
            tc.verifyEqual(numel(reqlinks), numRLinksOld+1);
            tc.verifyTrue(strcmp(reqlinks(end).reqsys, 'linktype_polarion'));
            
            % Check hyperlink and attachments did not increase
            jWorkItem = mgr.polarionAdapter.getWorkItem(pItemId);
            
            hyperlinks = jWorkItem.getHyperlinks();
            attachments = jWorkItem.getAttachments();
            links = jWorkItem.getLinkedWorkItemsDerived();

            tc.verifyEqual(numel(hyperlinks),numHyperlinksOld);
            tc.verifyEqual(numel(attachments), numAttachmentsOld);            
                
            % Check the surrogate work item
            sgWorkItem = mgr.polarionAdapter.getWorkItem(char(links(end).getWorkItemURI()));
            tc.verifyEqual(char(sgWorkItem.getTitle()), rItemId);
            tc.verifyEqual(numel(links), numDerivedLinksOld+1);
            tc.verifyEqual(numel(sgWorkItem.getHyperlinks()), 1);
            hyperlinks = sgWorkItem.getHyperlinks();
            tc.verifyEqual(char(hyperlinks(end).getUri()), mgr.matlabAdapter.getNavURL(rItemId));
            if pushImage
                % Check attachment
                imgName = [strrep(rItemId, ':', '-') '.png'];
                tc.verifyEqual(numel(sgWorkItem.getAttachments()),1);
                % Check embedded image
                doc = simpol.utils.XML.str2dom(char(sgWorkItem.getDescription().getContent()), 'fragment', true);
                [idxTag, imgTag, nTags] = findImageTag(mgr.polarionAdapter, doc, imgName);
                tc.verifyEqual(nTags, 1);
            else
                tc.verifyEqual(numel(sgWorkItem.getAttachments()),0);
                tc.verifyEqual(nTags, 0);
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
            
            mgr.removeLink(side, linkIdd);
            
            % Verify existance of link in simulink
            reqlinks = rmi('get', rItemId);
            tc.verifyEqual(numel(reqlinks), numRLinksOld-1);
            
            % Check hyperlink and attachments did not increase
            jWorkItem = mgr.polarionAdapter.getWorkItem(pItemId);
            
            hyperlinks = jWorkItem.getHyperlinks();
            attachments = jWorkItem.getAttachments();
            links = jWorkItem.getLinkedWorkItemsDerived();

            tc.verifyEqual(numel(hyperlinks),numHyperlinksOld);
            tc.verifyEqual(numel(attachments), numAttachmentsOld);  
            
            % Check that linking to the surrogate work item disappeared
            flagFound = false;
            for i = 1:numel(links)
                 sgWorkItem = mgr.polarionAdapter.getWorkItem(char(links(end).getWorkItemURI()));
                 if strcmp(char(sgWorkItem.getTitle()), rItemId)
                     flagFound = true;
                     break;
                 end
            end
            tc.verifyFalse(flagFound);
            
            % The surrogate work item cannot be removed...
                                
            
        end
    end
end

