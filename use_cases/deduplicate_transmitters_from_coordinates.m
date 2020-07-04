function [final_umi_cell_latitudes, final_umi_cell_longitudes] = deduplicate_transmitters_from_coordinates(umi_cell_latitudes, umi_cell_longitudes)

cells_index = 1;

for i = 1:length(umi_cell_latitudes)
    lat_original = umi_cell_latitudes(i);
    lon_original = umi_cell_longitudes(i);
    
    is_duplicated = false;
    
    for j=i:-1:1   
        lat_second = umi_cell_latitudes(j);
        lon_second = umi_cell_longitudes(j);
        if i~=j && lat_original==lat_second && lon_original==lon_second
            is_duplicated = true;
        elseif i~=j && ~is_point_far_enough(lat_original, lon_original, lat_second, lon_second, 30)
            is_duplicated = true;
        end
    end
    
    if ~is_duplicated
        final_umi_cell_latitudes(cells_index) = lat_original;
        final_umi_cell_longitudes(cells_index) = lon_original;
        cells_index = cells_index + 1;
    end
end
end

function [is_far_enough] = is_point_far_enough(lat_original, lon_original, lat_second, lon_second, distance)
    is_far_enough = true;    
    lat_difference = abs(lat_original - lat_second);
    lon_difference = abs(lon_original - lon_second);
    
    distance_factor = 0.00001*distance; % Transform into meters approx
    
    if distance_factor > lat_difference && distance_factor > lon_difference
        is_far_enough = false;
    end
end