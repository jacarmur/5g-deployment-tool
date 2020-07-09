function [transmitters] = get_transmitters_from_coordinates(latitudes, longitudes, tx_model)
power = tx_model.power;
frequency = tx_model.frequency;
height = tx_model.height;

antenna_element = get_antenna_element(tx_model.antenna_type, frequency);

number_of_txs = length(latitudes);
if strcmp(tx_model.name, 'uma')
    offset = load_offset_from_optimization_file(number_of_txs);
    number_of_txs = number_of_txs*3;
    cell_sector_angle = [0 120 240];
    cell_angles = zeros(1, number_of_txs);
    cell_nums = zeros(1, number_of_txs);
    cells_latitudes = latitudes;
    cells_longitudes = longitudes;

    for i = 1:3:number_of_txs
        cell_angles(i:i+2) = cell_sector_angle;
        cell_nums(i:i+2) = 1:3;
        cells_latitudes(i:i+2) = latitudes(fix(i/3)+1);
        cells_longitudes(i:i+2) = longitudes(fix(i/3)+1);
    end

    cell_angles = cell_angles + offset;

    channel_frequencies = zeros(1, number_of_txs);
    for i=1:number_of_txs
        channel_frequencies(i) = frequency;
        cell_names(i) = "Transmitter "+floor((i-1)/3+1)+" cell "+cell_nums(i);
    end
    transmitters = txsite("Name", cell_names, ...
        "Latitude", cells_latitudes, ...
        "Longitude", cells_longitudes, ...
        "AntennaHeight", height, ...
        "Antenna", antenna_element,...
        'AntennaAngle', cell_angles,...
        "TransmitterPower", power, ...
        "TransmitterFrequency", channel_frequencies);
else
    channel_frequencies = zeros(1, number_of_txs);
    for i=1:number_of_txs
        if strcmp(tx_model.name, 'umi_coverage')
            channel_frequencies(i) = frequency - mod(i,2)*100e6;
        else
            channel_frequencies(i) = frequency;
        end
        cell_names(i) = "UMI "+tx_model.name+" "+i;
    end
    transmitters = txsite("Name", cell_names, ...
        "Latitude", latitudes, ...
        "Longitude", longitudes, ...
        "AntennaHeight", height, ...
        "Antenna", antenna_element,...
        "TransmitterPower", power, ...
        "TransmitterFrequency", channel_frequencies);
end

end

function antenna = get_antenna_element(antenna_name, frequency)
    switch antenna_name
        case 'isotropic'
            antenna = phased.IsotropicAntennaElement;
        case 'sector'
            antenna = get_8x8_antenna(frequency);
        otherwise
            antenna = phased.IsotropicAntennaElement;
    end
end

function [patchElement] = get_patch_antenna_element(frequency)

patchElement = design(patchMicrostrip, frequency);
patchElement.Width = patchElement.Length;
patchElement.Tilt = 90;
patchElement.TiltAxis = [0 1 0];

end

function [antenna_element] = get_custom_antenna_element()

azimuth_vector = -180:180;
elevation_vector = -90:90;
maximum_attenuation_db = 30;
tilt = -12;
azimuth_3dB = 65;
elevation_3dB = 65;

[azimuths, elevations] = meshgrid(azimuth_vector, elevation_vector);
azimuth_magnitude_pattern = -12*(azimuths/azimuth_3dB).^2;
elevation_magnitude_pattern = -12*((elevations-tilt)/elevation_3dB).^2;
combined_magnitude_pattern = azimuth_magnitude_pattern + elevation_magnitude_pattern;
combined_magnitude_pattern(combined_magnitude_pattern<-maximum_attenuation_db) = -maximum_attenuation_db;
phase_pattern = zeros(size(combined_magnitude_pattern));

antenna_element = phased.CustomAntennaElement(...
    'AzimuthAngles',azimuth_vector, ...
    'ElevationAngles',elevation_vector, ...
    'MagnitudePattern',combined_magnitude_pattern, ...
    'PhasePattern',phase_pattern);

end

function antenna = get_8x8_antenna(frequency)
number_of_rows = 8;
number_of_columns = 8;

lambda = physconst('lightspeed')/frequency;
distance_row = lambda/2;
distance_columns = lambda/2;

dB_down = 30;
taper_z = chebwin(number_of_rows, dB_down);
taper_y = chebwin(number_of_columns, dB_down);
final_taper = taper_z*taper_y.';
antenna_element = get_custom_antenna_element();
antenna = phased.URA('Size',[number_of_rows number_of_columns], ...
    'Element',antenna_element, ...
    'ElementSpacing',[distance_row distance_columns], ...
    'Taper',final_taper, ...
    'ArrayNormal','x');
end