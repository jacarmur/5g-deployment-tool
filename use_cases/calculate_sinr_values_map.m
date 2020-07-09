function [data_lats, data_lons, gridSize, sinr_data] = calculate_sinr_values_map(transmitters, coordinates_bbox, model_name, varargin)
propagation_model = propagationModel(model_name);
validateattributes(transmitters, {'txsite'}, {'nonempty'}, 'sinr', '', 1);

input_parameters = inputParser;
input_parameters = validate_sinr_values_parameters(input_parameters, varargin{:});

viewer = rfprop.internal.Validators.validateMap(input_parameters, 'sinr');

sig_source = validate_signal_source(input_parameters);
transmitters = transmitters(:);
if isa(sig_source,'txsite')
    if ~ismember(sig_source, transmitters)
        transmitters = [transmitters; sig_source];
    end
end
num_tx = numel(transmitters);

txs_coordinates = rfprop.internal.AntennaSiteCoordinates.createFromAntennaSites(transmitters, viewer);
txslatlon = transmitters.location;

rx_gain = 2.1;
rx_antenna_height = 1;
noise_power = -107;

if ismember('MaxRange', input_parameters.UsingDefaults)
    max_range = rfprop.internal.Validators.defaultMaxRange(txslatlon, propagation_model, viewer);
else
    max_range = rfprop.internal.Validators.validateNumericMaxRange(input_parameters.Results.MaxRange, propagation_model, num_tx, viewer, 'sinr');
end
[results, is_auto_res] = rfprop.internal.Validators.validateResolution(input_parameters, max_range, 'sinr');
data_range = rfprop.internal.Validators.validateDataRange(txslatlon, max_range, results, viewer.UseTerrain);

maximum_image_size = viewer.MaxImageSize;
north_latitude = coordinates_bbox.maximum_latitude;
south_latitude = coordinates_bbox.minimum_latitude;
east_longitude = coordinates_bbox.maximum_longitude;
west_longitude = coordinates_bbox.minimum_longitude;

[grid_lats, grid_lons, ~] = rfprop.internal.MapUtils.geogrid(...
    north_latitude, south_latitude, east_longitude, west_longitude, results, is_auto_res, max_range, maximum_image_size, 'sinr');
gridSize = size(grid_lats);

[data_lats, data_lons] = rfprop.internal.MapUtils.georange(...
    transmitters, grid_lats(:), grid_lons(:), data_range, viewer.TerrainSource);

type = 'power';

receivers = rxsite(...
    'Name', 'internal.sinrsite', ...
    'Latitude', data_lats, ...
    'Longitude', data_lons, ...
    'AntennaHeight', rx_antenna_height);

signal_strength = sigstrength(receivers, transmitters, propagation_model, ...
    'Type', type, ...
    'ReceiverGain', rx_gain, ...
    'Map', viewer, ...
    'TransmitterAntennaSiteCoordinates', txs_coordinates);

txs_coordinates.addCustomData('SignalStrength', signal_strength);

sinr_data = sinr(receivers, transmitters, ...
    'SignalSource', sig_source, ...
    'ReceiverNoisePower', noise_power, ...
    'PropagationModel', propagation_model, ...
    'ReceiverGain', rx_gain, ...
    'TransmitterAntennaSiteCoordinates', txs_coordinates, ...
    'Map', viewer);

end

function [input_parameters] = validate_sinr_values_parameters(input_parameters, varargin)

if mod(numel(varargin),2)
    input_parameters.addOptional('PropagationModel', [], @(x)ischar(x)||isstring(x)||isa(x,'rfprop.PropagationModel'));
else
    input_parameters.addParameter('PropagationModel', []);
end
input_parameters.addParameter('SignalSource', 'strongest');
input_parameters.addParameter('Values', -5:20);
input_parameters.addParameter('Resolution', 'auto');
input_parameters.addParameter('ReceiverGain', 2.1);
input_parameters.addParameter('ReceiverAntennaHeight', 1);
input_parameters.addParameter('ReceiverNoisePower', -107);
input_parameters.addParameter('Animation', '');
input_parameters.addParameter('MaxRange', []);
input_parameters.addParameter('Colormap', 'jet');
input_parameters.addParameter('ColorLimits', []);
input_parameters.addParameter('Transparency', 0.4);
input_parameters.addParameter('ShowLegend', true);
input_parameters.addParameter('ReceiverLocationsLayout', []);
input_parameters.addParameter('MaxImageResolutionFactor', 5);
input_parameters.addParameter('RadialResolutionFactor', 2);
input_parameters.addParameter('Map', []);
input_parameters.parse(varargin{:});

end

function sig_source = validate_signal_source(parameters)

try
    sig_source = parameters.Results.SignalSource;
    if ischar(sig_source) || isstring(sig_source)
        sig_source = validatestring(sig_source, {'strongest'}, ...
            'sinr', 'SignalSource');
    else
        validateattributes(sig_source, {'txsite'}, {'scalar'}, ...
            'sinr', 'SignalSource');
    end
catch exception
    throwAsCaller(exception);
end
end