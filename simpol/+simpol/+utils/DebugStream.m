classdef DebugStream < handle
    %DebugStream RAII class registering a listener that dumps user
    % notifications for debugging purposes.
    
    properties
        listener
    end
    
    methods
        function h = DebugStream(mgr)
            assert(isa(mgr, "simpol.Manager"));
            h.listener = listener(mgr, 'UserNotificationEvent',...
                @(source, eventData) h.handleNotification(source, eventData));
        end
        
        function handleNotification(~, ~, eventData)
            import simpol.utils.*;
            
            switch eventData.type
                case UserNotificationType.STATUS
                    disp(eventData.message);
                case UserNotificationType.INFO
                   disp(eventData.message);
                case UserNotificationType.WARN
                    warning(eventData.message);    
                case UserNotificationType.ERROR
                    error(eventData.message);                
                otherwise
                    % Nothing
            end
        end
    end
end

