function [transmitters] = get_transmitters_from_coordinates(latitudes, longitudes, power, frequency, offset)

antennaElement = get_8x8_antenna(frequency);

number_of_txs = length(latitudes)*3;

% Numero de transmitters * 3 offsets aleatorios
cell_sector_angle = [0 120 240];
cell_angles = zeros(1, number_of_txs);
cell_nums = zeros(1, number_of_txs);
cells_latitudes = zeros(1, number_of_txs);
cells_longitudes = zeros(1, number_of_txs);

for i = 1:3:number_of_txs
    cell_angles(i:i+2) = cell_sector_angle;
    cell_nums(i:i+2) = 1:3;
    cells_latitudes(i:i+2) = latitudes(fix(i/3)+1);
    cells_longitudes(i:i+2) = longitudes(fix(i/3)+1);
end

cell_angles = cell_angles + offset;

channel_frequencies = zeros(1, number_of_txs);
powers = zeros(1, number_of_txs);
height = zeros(1, number_of_txs);
for i=1:number_of_txs
    channel_frequencies(i) = frequency;
    cell_names(i) = "Transmitter "+floor((i-1)/3+1)+" cell "+cell_nums(i);
    %antenna_elements(i) = antennaElement;
    powers(i) = power;
    height(i) = 15;
end

transmitters = txsite("Name", cell_names, ...
    "Latitude", cells_latitudes, ...
    "Longitude", cells_longitudes, ...
    "AntennaHeight", height, ...
    "Antenna", antennaElement,...
    'AntennaAngle', cell_angles,...
    "TransmitterPower", powers, ...
    "TransmitterFrequency", channel_frequencies);

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