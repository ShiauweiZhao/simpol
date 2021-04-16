classdef ModalLock < handle
    % ModalLock Fakes the lock if a modal dialog is opened using a
    % uiprogressdlg element.
    % RAII object - lock is released when object is destroyed.
    
    properties
        progressLockDlg;
    end
    
    methods
        function h = ModalLock(fig)
            h.progressLockDlg = uiprogressdlg(fig,...
                "Message", "Child window open...");
        end
        
        function delete(h)
            h.progressLockDlg.close();
        end
    end
end

