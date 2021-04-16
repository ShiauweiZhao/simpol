classdef SideType
    % SideType Enumeration for the linking side. SimPol links MATLAB items with
    % Polarion, so POLARION and MATLAB are the possible sides.
    
    enumeration
        POLARION
        MATLAB
    end
    
    methods(Static)
        function otherSide = flip(side)
            if side == simpol.SideType.POLARION
                otherSide = simpol.SideType.MATLAB;
            else
                otherSide = simpol.SideType.POLARION;
            end            
        end        
    end
end

