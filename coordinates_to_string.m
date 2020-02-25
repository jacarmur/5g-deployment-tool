function [formatted] = coordinates_to_string(lat1,lon1,lat2,lon2)
    coordinates_list = [string(lat1), string(lon1), string(lat2), string(lon2)];
    formatted = strjoin(coordinates_list, ',');
end

