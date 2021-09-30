classdef dummyDirClass
    
    properties
        Property1
    end
    
    methods
        function obj = dummyDirClass(inputArg1,inputArg2)
            obj.Property1 = inputArg1 + inputArg2;
        end
        % Internal function
        function obj = intFun(obj, inputArg1,inputArg2)
            obj.Property1 = inputArg1 - inputArg2;
        end
    end
    
    methods (Static)        
        % External function
        outputArg = extFun(inputArg1,inputArg2)
    end
end

