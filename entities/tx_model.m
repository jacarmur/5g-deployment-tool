classdef tx_model
    %TX_MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
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
            %TX_MODEL Construct an instance of this class
            obj.frequency = frequency;
            obj.power = power;
            obj.antenna_type = antenna_type;
            obj.height = height;
            obj.name = name;
        end
    end
end
