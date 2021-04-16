classdef AbstractSuspicionModel < handle & simpol.utils.UserNotificationInterface
           
    methods(Abstract, Static)
        % Gets a list of link pairs Nx2. Returns a logical vector of Nx2,
        % indicating of the particular link is suspected.
        [polarionIsSuspected, matlabIsSuspected] = ...
            areLinksSuspected(polarionAdapter, polarionLinkProps, ...
                              rmiAdapter, matlabLinkProps);
        
        % If this setting is enabled, SimPol can unsuspect the link itself
        % and provides the necessary methods.
        b = allowsUnsuspect(h);
    end
    
end

