function [receivers, transmitters, parameters] = validate_parameters(receivers, transmitters, input_parameters, varargin)

input_parameters.addParameter('SignalSource', 'strongest');
input_parameters.addParameter('ReceiverNoisePower', -107);
input_parameters.addParameter('ReceiverGain', []);
input_parameters.addParameter('ReceiverAntennaHeight', []);
input_parameters.addParameter('Map', []);
input_parameters.addParameter('TransmitterAntennaSiteCoordinates', []);
input_parameters.parse(varargin{:});

parameters.numRxs = numel(receivers);
parameters.map = rfprop.internal.Validators.validateMapTerrainSource(input_parameters, 'sinr');
parameters.propagation_model = rfprop.internal.Validators.validatePropagationModel(input_parameters, parameters.map, 'sinr');
parameters.noisePower = validate_receiver_noise_power(input_parameters);
[parameters.rxGain, parameters.usingDefaultGain] = validate_receiver_gain(input_parameters);
validate_receiver_antenna_height(input_parameters);

transmitters = transmitters(:);

parameters.txsCoords = rfprop.internal.Validators.validateAntennaSiteCoordinates(...
    input_parameters.Results.TransmitterAntennaSiteCoordinates, transmitters, parameters.map, 'sinr');

end

function noise_power =  validate_receiver_noise_power(params)

try
    noise_power = params.Results.ReceiverNoisePower;
    validateattributes(noise_power, {'numeric'}, {'real','finite','nonnan','nonsparse','scalar'}, ...
        'sinr', 'ReceiverNoisePower');
catch exception
    throwAsCaller(exception);
end
end

function [rx_gain, using_default_gain] = validate_receiver_gain(parameters)

try
    rx_gain = parameters.Results.ReceiverGain;
    using_default_gain = ismember('ReceiverGain', parameters.UsingDefaults);
    if ~using_default_gain
        validateattributes(rx_gain,{'numeric'}, {'real','finite','nonnan','nonsparse','scalar'}, ...
            'sinr', 'ReceiverGain');
    end
catch exception
    throwAsCaller(exception);
end
end

function [rx_height, using_default_height] = validate_receiver_antenna_height(parameters)

try
    rx_height = parameters.Results.ReceiverAntennaHeight;
    using_default_height = ismember('ReceiverAntennaHeight', parameters.UsingDefaults);
    if ~using_default_height
        validateattributes(rx_height,{'numeric'}, {'real','finite','nonnan','nonsparse','scalar','nonnegative', ...
            '<=',rfprop.Constants.MaxPropagationDistance}, 'sinr', 'ReceiverAntennaHeight');
    end
catch exception
    throwAsCaller(exception);
end
end
