function [sinr_matrix] = get_sinr_matrix_for_all_the_transmitters(receivers, transmitters, varargin)
% Pontentially customizable params: noisePower, propagationModel, freqs

% Validate site inputs
validateattributes(receivers,{'rxsite'},{'nonempty'},'sinr','',1);
validateattributes(transmitters,{'txsite'},{'nonempty'},'sinr','',2);

% Process optional inputs
input_parameters = inputParser;
if nargin > 2 && mod(numel(varargin),2)
    % Validator function is necessary for inputParser to allow string
    % option instead of treating it like parameter name
    input_parameters.addOptional('PropagationModel', [], @(x)ischar(x)||isstring(x)||isa(x,'rfprop.PropagationModel'));
else
    input_parameters.addParameter('PropagationModel', []);
end

[receivers, transmitters, validated_params] = validate_parameters(receivers, transmitters, input_parameters, varargin{:});

% Compute SignalStrength values if not passed in
% Calculate signal strengths (in dBm) at receivers due to transmitters
args = {'Type', 'power', ...
    'TransmitterAntennaSiteCoordinates', validated_params.txsCoords};
if ~validated_params.usingDefaultGain
    args = [args, 'ReceiverGain', rxGain];
end
signal_strength = sigstrength(receivers, transmitters, validated_params.propagation_model, args{:});

transmitter_frequencies = [transmitters.TransmitterFrequency];

% Calculate SINR for each receiver
number_of_transmitters = length(transmitters);
sinr_matrix = zeros(number_of_transmitters, validated_params.numRxs);
for rxInd = 1:validated_params.numRxs
    for txInd = 1:number_of_transmitters
        % Get signal strengths from transmitters to this receiver
        sigStrengths = signal_strength(:,rxInd)';    

        sigSourceInd = txInd;
        sigSourcePower = sigStrengths(sigSourceInd);

        % Get interference frequencies and powers (remove signal source from txs)
        intSourceFqs = transmitter_frequencies;
        intSourcePowers = sigStrengths;
        intSourceFqs(sigSourceInd) = [];
        intSourcePowers(sigSourceInd) = [];

        % Compute interference power from sources with matching frequency
        sigSourceFq = transmitter_frequencies(sigSourceInd);
        intSourceInd = (intSourceFqs == sigSourceFq);
        intSourcePowers = intSourcePowers(intSourceInd);
        interferencePower = sum(intSourcePowers);

        % Compute SINR in dB
        receiver_sinr = sigSourcePower / (interferencePower + validated_params.noisePower);
        receiver_sinr_db = 10*log10(receiver_sinr); % Convert to dB

        % Assign output
        sinr_matrix(txInd, rxInd) = receiver_sinr_db;
    end
end

end
