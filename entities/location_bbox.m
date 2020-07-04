classdef location_bbox
    %LOCATION_BBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        minimum_latitude
        maximum_latitude
        minimum_longitude
        maximum_longitude
    end
    
    methods
        function obj = location_bbox(minimum_latitude, maximum_latitude,...
                minimum_longitude, maximum_longitude)
            %LOCATION_BBOX Construct an instance of this class
            obj.minimum_latitude = minimum_latitude;
            obj.maximum_latitude = maximum_latitude;
            obj.minimum_longitude = minimum_longitude;
            obj.maximum_longitude = maximum_longitude;
        end
        
        function formatted_string = get_cells_bbox_string(obj)
            %get_cells_bbox_string Returns a string formatted for the cells
            %request
            lat1 = obj.minimum_latitude;
            lon1 = obj.minimum_longitude;
            lat2 = obj.maximum_latitude;
            lon2 = obj.maximum_longitude;
            
            formatted_string = coordinates_to_string(lat1, lon1, lat2, lon2);
        end
        
        function formatted_string = coordinates_to_string(lat1, lon1, lat2, lon2)
            %FORMATTED_STRING returns lats and lons separated by commas as 
            %string 
            coordinates_list = [string(lat1), string(lon1), string(lat2), string(lon2)];
            formatted_string = strjoin(coordinates_list, ',');
        end
        
        function formatted_string = get_maps_bbox_string(obj)
            %get_maps_bbox_string Returns a string formatted for the Maps
            %request
            lat1 = obj.minimum_latitude;
            lon1 = obj.minimum_longitude;
            lat2 = obj.maximum_latitude;
            lon2 = obj.maximum_longitude;
            
            formatted_string = coordinates_to_string(lon1, lat1, lon2, lat2);
        end
        
        function formatted_string = get_social_attractors_bbox_string(obj)
            %get_maps_bbox_string Returns a string formatted for the Maps
            %social attractors identifier
            lat1 = obj.minimum_latitude;
            lon1 = obj.minimum_longitude;
            lat2 = obj.maximum_latitude;
            lon2 = obj.maximum_longitude;
            
            coordinates_list = [string(lat1), string(lon1), string(lat2), string(lon2)];
            formatted_string = strjoin(coordinates_list, ' ');
        end
        
    end
end

