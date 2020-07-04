function [transmitters] = get_transmitters_from_coordinates(latitudes, longitudes, tx_model)
power = tx_model.power;
frequency = tx_model.frequency;
height = tx_model.height;

antenna_element = get_antenna_element(tx_model.antenna_type, frequency);

number_of_txs = length(latitudes);
% Numero de transmitters * 3 offsets aleatorios
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

function [antennaElement] = get_custom_antenna_element()

% Define pattern parameters
azvec = -180:180;
elvec = -90:90;
Am = 30; % Maximum attenuation (dB)
tilt = -12; % Tilt angle
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

function antenna = get_8x8_antenna(fq)
    % Define array size
nrow = 8;
ncol = 8;

% Define element spacing
lambda = physconst('lightspeed')/fq;
drow = lambda/2;
dcol = lambda/2;

% Define taper to reduce sidelobes 
dBdown = 30;
taperz = chebwin(nrow,dBdown);
tapery = chebwin(ncol,dBdown);
tap = taperz*tapery.'; % Multiply vector tapers to get 8-by-8 taper values
antennaElement = get_custom_antenna_element();
% Create 8-by-8 antenna array
antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');
end