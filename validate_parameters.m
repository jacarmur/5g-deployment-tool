function [receivers, transmitters, params] = validate_parameters(receivers, transmitters, input_parameters, varargin)
%VALIDATE_PARAMETERS Summary of this function goes here
%   Detailed explanation goes here

input_parameters.addParameter('SignalSource', 'strongest');
input_parameters.addParameter('ReceiverNoisePower', -107);
input_parameters.addParameter('ReceiverGain', []);
input_parameters.addParameter('ReceiverAntennaHeight', []);
input_parameters.addParameter('Map', []);
input_parameters.addParameter('TransmitterAntennaSiteCoordinates', []);
input_parameters.parse(varargin{:});

% Validate and get parameters
params.numRxs = numel(receivers);
params.map = rfprop.internal.Validators.validateMapTerrainSource(input_parameters, 'sinr');
params.propagation_model = rfprop.internal.Validators.validatePropagationModel(input_parameters, params.map, 'sinr');
sigSource = validateSignalSource(input_parameters, params.numRxs);
params.noisePower = validateReceiverNoisePower(input_parameters);
[params.rxGain, params.usingDefaultGain] = validateReceiverGain(input_parameters);
validateReceiverAntennaHeight(input_parameters);

% Create vector array of all txs
transmitters = transmitters(:);
usingSiteSigSource = isa(sigSource,'txsite');
if usingSiteSigSource
    % Include signal sources in txsite list
    transmitters = union(transmitters,sigSource,'stable');
end

params.txsCoords = rfprop.internal.Validators.validateAntennaSiteCoordinates(...
    input_parameters.Results.TransmitterAntennaSiteCoordinates, transmitters, params.map, 'sinr');

end


function sigsource = validateSignalSource(params, numRxs)

try
    sigsource = params.Results.SignalSource;
    if ischar(sigsource) || isstring(sigsource)
        sigsource = validatestring(sigsource, {'strongest'}, ...
            'sinr','SignalSource');
    elseif isscalar(sigsource)
        validateattributes(sigsource,{'txsite'}, {'scalar'}, ...
            'sinr','SignalSource');
    else
        validateattributes(sigsource,{'txsite'}, {'numel',numRxs}, ...
            'sinr','SignalSource');
        sigsource = sigsource(:); % Guarantee column vector
    end
catch exception
    throwAsCaller(exception);
end
end


function noisePower =  validateReceiverNoisePower(params)

try
    noisePower = params.Results.ReceiverNoisePower;
    validateattributes(noisePower, {'numeric'}, {'real','finite','nonnan','nonsparse','scalar'}, ...
        'sinr', 'ReceiverNoisePower');
catch exception
    throwAsCaller(exception);
end
end

function [rxGain, usingDefaultGain] = validateReceiverGain(params)

try
    rxGain = params.Results.ReceiverGain;
    usingDefaultGain = ismember('ReceiverGain',params.UsingDefaults);
    if ~usingDefaultGain
        validateattributes(rxGain,{'numeric'}, {'real','finite','nonnan','nonsparse','scalar'}, ...
            'sinr', 'ReceiverGain');
    end
catch exception
    throwAsCaller(exception);
end
end

function [rxHeight, usingDefaultHeight] = validateReceiverAntennaHeight(params)

try
    rxHeight = params.Results.ReceiverAntennaHeight;
    usingDefaultHeight = ismember('ReceiverAntennaHeight',params.UsingDefaults);
    if ~usingDefaultHeight
        validateattributes(rxHeight,{'numeric'}, {'real','finite','nonnan','nonsparse','scalar','nonnegative', ...
            '<=',rfprop.Constants.MaxPropagationDistance}, 'sinr', 'ReceiverAntennaHeight');
    end
catch exception
    throwAsCaller(exception);
end
end
