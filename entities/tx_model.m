classdef tx_model
    properties
        frequency
        power
        antenna_type
        height
        name
    end
    
    methods
        function obj = tx_model(frequency, power,...
                antenna_type, height, name)
            obj.frequency = frequency;
            obj.power = power;
            obj.antenna_type = antenna_type;
            obj.height = height;
            obj.name = name;
        end
    end
end
