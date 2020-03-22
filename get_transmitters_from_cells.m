function [transmitters] = get_transmitters_from_cells(selected_phone_cells, frequency, power, number_of_channels)
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
        end
    end
    
    if ~is_duplicated
        selected_phone_cells_candidates(cells_index) = selected_phone_cells(i);
        cells_index = cells_index + 1;
    end
end

numTx = length(selected_phone_cells_candidates);
for i = 1:numTx
        lat = selected_phone_cells_candidates(i).lat;
        lon = selected_phone_cells_candidates(i).lon;
        channel = randi(number_of_channels)-1;
        transmitters(i) = txsite("Name","Transmitter "+i, ...
        "Latitude",lat, ...
        "Longitude",lon, ...
        "AntennaHeight",10, ...
        "TransmitterPower",power, ...
        "TransmitterFrequency",frequency('3')+channel*20e6);
end
end

