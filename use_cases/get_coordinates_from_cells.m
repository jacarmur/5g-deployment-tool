function [latitudes, longitudes] = get_coordinates_from_cells(selected_phone_cells)

selected_phone_cells_candidates = deduplicate_phone_cells(selected_phone_cells);
latitudes = zeros(1, length(selected_phone_cells_candidates));
longitudes = zeros(1, length(selected_phone_cells_candidates));

for i = 1:length(selected_phone_cells_candidates)
    latitudes(i) = selected_phone_cells_candidates(i).lat;
    longitudes(i) = selected_phone_cells_candidates(i).lon;
end

end

function selected_phone_cells_candidates = deduplicate_phone_cells(selected_phone_cells)
cells_index = 1;

for i = 1:length(selected_phone_cells)
    lat_original = selected_phone_cells(i).lat;
    lon_original = selected_phone_cells(i).lon;
    
    is_duplicated = false;
    
    for j=i:-1:1   
        lat_second = selected_phone_cells(j).lat;
        lon_second = selected_phone_cells(j).lon;
        if i~=j && lat_original==lat_second && lon_original==lon_second
            is_duplicated = true;
        elseif i~=j && ~is_point_far_enough(lat_original, lon_original, lat_second, lon_second, 100)
            is_duplicated = true;
        end
    end
    
    if ~is_duplicated
        selected_phone_cells_candidates(cells_index) = selected_phone_cells(i);
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