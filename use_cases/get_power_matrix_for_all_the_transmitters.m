function [power_matrix] = get_power_matrix_for_all_the_transmitters(receivers, transmitters, varargin)

validateattributes(receivers,{'rxsite'},{'nonempty'},'sinr','',1);
validateattributes(transmitters,{'txsite'},{'nonempty'},'sinr','',2);

input_parameters = inputParser;
if nargin > 2 && mod(numel(varargin),2)
    input_parameters.addOptional('PropagationModel', [], @(x)ischar(x)||isstring(x)||isa(x,'rfprop.PropagationModel'));
else
    input_parameters.addParameter('PropagationModel', []);
end

[receivers, transmitters, validated_params] = validate_parameters(receivers, transmitters, input_parameters, varargin{:});

args = {'Type', 'power', ...
    'TransmitterAntennaSiteCoordinates', validated_params.txsCoords};
if ~validated_params.usingDefaultGain
    args = [args, 'ReceiverGain', rxGain];
end
signal_strength = sigstrength(receivers, transmitters, validated_params.propagation_model, args{:});

number_of_transmitters = length(transmitters);
power_matrix = zeros(number_of_transmitters, validated_params.numRxs);
for rxInd = 1:validated_params.numRxs
    for txInd = 1:number_of_transmitters
        sigStrengths = signal_strength(:,rxInd)';    

        sigSourceInd = txInd;
        sigSourcePower = sigStrengths(sigSourceInd);
        power_matrix(txInd, rxInd) = sigSourcePower;
    end
end
end

