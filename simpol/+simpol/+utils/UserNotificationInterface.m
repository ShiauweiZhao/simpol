classdef UserNotificationInterface < handle
    % UserNotificationInterface Generic interface to emit user
    % notifications.
    % Derive other classes from this class, if they shall use the common
    % notification stream.
    
    events
        UserNotificationEvent
    end
    
    % -----------------------------------------------------------------
    % -----------------------------------------------------------------
    
    methods
        
        function notifyStatus(h, message)
            % Create a user notifiction of type STATUS.
            import simpol.utils.*
            
            notify(h, 'UserNotificationEvent',...
                UserNotification(UserNotificationType.STATUS,...
                convertCharsToStrings(message), ""));
        end
        
        % -----------------------------------------------------------------
        
        function notifyInfo(h, message, title)
            % Create a user notifiction of type INFO.
            import simpol.utils.*
                       
            if nargin < 3
                title = "Information";
            end
            
            notify(h, 'UserNotificationEvent',...
                UserNotification(UserNotificationType.INFO,...
                convertCharsToStrings(message), convertCharsToStrings(title)));
        end 
        
        % -----------------------------------------------------------------
        
        function notifyWarn(h, message, title)
            % Create a user notifiction of type WARN.
            import simpol.utils.*
            
            if nargin < 3
                title = "Warning";
            end            
            
            notify(h, 'UserNotificationEvent',...
                UserNotification(UserNotificationType.WARN,...
                convertCharsToStrings(message), convertCharsToStrings(title)));
        end 
        
        % -----------------------------------------------------------------
        
        function notifyError(h, message, title)
            % Create a user notifiction of type ERROR.
            import simpol.utils.*
            
            if nargin < 3
                title = "Error";
            end            
            
            notify(h, 'UserNotificationEvent',...
                UserNotification(UserNotificationType.ERROR,...
                convertCharsToStrings(message), convertCharsToStrings(title)));
        end          
        
    end
    
end