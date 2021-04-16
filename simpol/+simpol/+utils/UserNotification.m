classdef (ConstructOnLoad) UserNotification < event.EventData
    % UserNotification Wrapper for event data used for user notifications
    
    properties
        type simpol.utils.UserNotificationType = simpol.utils.UserNotificationType.INFO
        message string = ""
        title string = ""        
    end
    
    methods
        function data = UserNotification(type, message, title)
            data.type = type;
            data.message = message;
            data.title = title;            
        end
    end
end