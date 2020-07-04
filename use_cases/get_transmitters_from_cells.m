function [transmitters] = get_transmitters_from_cells(selected_phone_cells, frequencies, power, number_of_channels, offset)
frequency = frequencies('3');
antennaElement = get_patch_antenna_element(frequency);

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
cell_sector_angles = [30 150 270] + offset;
for i = 1:numTx
    cell_num = 1;
    for cell_angle = cell_sector_angles
        lat = selected_phone_cells_candidates(i).lat;
        lon = selected_phone_cells_candidates(i).lon;
        channel = randi(number_of_channels)-1;
        transmitters((i-1)*3+cell_num) = txsite("Name","Transmitter "+i+" cell "+cell_num, ...
        "Latitude",lat, ...
        "Longitude",lon, ...
        "AntennaHeight",10, ...
        "Antenna", antennaElement,...
        'AntennaAngle', cell_angle,...
        "TransmitterPower", power, ...
        "TransmitterFrequency", frequency+channel*20e6);
        cell_num = cell_num + 1;
    end
end
end

function [patchElement] = get_patch_antenna_element(frequency)

patchElement = design(patchMicrostrip, frequency);
patchElement.Width = patchElement.Length;
patchElement.Tilt = 90;
patchElement.TiltAxis = [0 1 0];

end

function [antennaElement] = get_custom_antenna_element()

% Define pattern parameters
azvec = -180:180;
elvec = -90:90;
Am = 30; % Maximum attenuation (dB)
tilt = 0; % Tilt angle
az3dB = 65; % 3 dB bandwidth in azimuth
el3dB = 65; % 3 dB bandwidth in elevation

% Define antenna pattern
[az,el] = meshgrid(azvec,elvec);
azMagPattern = -12*(az/az3dB).^2;
elMagPattern = -12*((el-tilt)/el3dB).^2;
combinedMagPattern = azMagPattern + elMagPattern;
combinedMagPattern(combinedMagPattern<-Am) = -Am; % Saturate at max attenuation
phasepattern = zeros(size(combinedMagPattern));

% Create antenna element
antennaElement = phased.CustomAntennaElement(...
    'AzimuthAngles',azvec, ...
    'ElevationAngles',elvec, ...
    'MagnitudePattern',combinedMagPattern, ...
    'PhasePattern',phasepattern);

end