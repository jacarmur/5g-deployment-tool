function [] = plot_values_map(transmitters, datalats, datalons, gridSize, data, varargin)
validateattributes(transmitters, {'txsite'}, {'nonempty'}, 'sinr', '', 1);

input_parameters = inputParser;
input_parameters = validate_sinr_values_parameters(input_parameters, varargin{:});

viewer = rfprop.internal.Validators.validateMap(input_parameters, 'sinr');
viewer.validateWebGraphicsSupport;
is_viewer_initially_visible = viewer.Visible;
if is_viewer_initially_visible && ~viewer.Visible
    return
end
if is_viewer_initially_visible
    show_animation = 'none';
else
    show_animation = 'zoom';
end

txs_coordinates = rfprop.internal.AntennaSiteCoordinates.createFromAntennaSites(transmitters, viewer);
txs_latlon = transmitters.location;
show(transmitters, 'Map', viewer, 'Animation', show_animation, ...
    'AntennaSiteCoordinates', txs_coordinates);
on_forced_exit = rfprop.internal.onExit(@()hideBusyMessage(viewer));
viewer.showBusyMessage(message('shared_channel:rfprop:SINRMapBusyMessage').getString);

viewer = rfprop.internal.Validators.validateMap(input_parameters, 'sinr');
viewer.validateWebGraphicsSupport;

%%
animation = rfprop.internal.Validators.validateGraphicsControls(input_parameters, 'sinr');
color_limit = rfprop.internal.Validators.validateColorLimits(input_parameters, [-5 20], 'sinr');
color_map = rfprop.internal.Validators.validateColorMap(input_parameters, 'sinr');
transparency = 0.4;
show_legend = 1;
propagation_model = rfprop.internal.Validators.validatePropagationModel(input_parameters, viewer, 'sinr');
max_image_resolution_factor = input_parameters.Results.MaxImageResolutionFactor;
max_image_size = viewer.MaxImageSize;
max_range = rfprop.internal.Validators.defaultMaxRange(txs_latlon, propagation_model, viewer);
[results, ~] = rfprop.internal.Validators.validateResolution(input_parameters, max_range, 'sinr');

%%

number_of_txs = length(transmitters);
cell_ids = cell(1, number_of_txs);
for k = 1:number_of_txs
    cell_ids{k} = transmitters(k).Name;
end
visual_type = 'sinr';
color_data = struct('Colormap',color_map,'ColorLimits',color_limit);
viewer.validateImageVisualization(cell_ids, visual_type, color_data);

image_size = rfprop.internal.Validators.validateImageSize(...
    gridSize, max_image_resolution_factor, max_image_size, results, 'sinr');

%%

if site_viewer_was_closed(viewer)
    return
end

visual_type = 'sinr';
values = (-5:20)';
contourmap(transmitters, datalats, datalons, data, visual_type, ...
    'Animation', animation, ...
    'Map', viewer, ...
    'Levels', values, ...
    'ColorLimits', color_limit, ...
    'Colormap', color_map, ...
    'Transparency', transparency, ...
    'ShowLegend', show_legend, ...
    'ImageSize', image_size, ...
    'MaxRange', max_range, ...
    'LegendTitle', message('shared_channel:rfprop:SINRLegendTitle').getString, ...
    'SaturateColorFloor', true, ...
    'AntennaSiteCoordinates', txs_coordinates);

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

function was_closed = site_viewer_was_closed(viewer)
was_closed = viewer.LaunchWebWindow && ~viewer.Visible;
end
