function [] = plot_values_map(transmitters, datalats, datalons, gridSize, data, varargin)
validateattributes(transmitters, {'txsite'}, {'nonempty'}, 'sinr', '', 1);

input_parameters = inputParser;
input_parameters = validate_sinr_values_parameters(input_parameters, varargin{:});

viewer = rfprop.internal.Validators.validateMap(input_parameters, 'sinr');
is_viewer_initially_visible = viewer.Visible;
if is_viewer_initially_visible && ~viewer.Visible
    return
end
if is_viewer_initially_visible
    show_animation = 'none';
else
    show_animation = 'zoom';
end

txs_latlon = transmitters.location;
icons = get_icons(transmitters);
icons_strings = cellstr(icons);
for i = 1:length(transmitters)
    show(transmitters(i), 'Map', viewer, 'Animation', show_animation, 'Icon', icons_strings{i});
end
viewer.showBusyMessage(message('shared_channel:rfprop:SINRMapBusyMessage').getString);

viewer = rfprop.internal.Validators.validateMap(input_parameters, 'sinr');

%%
color_limit = rfprop.internal.Validators.validateColorLimits(input_parameters, [-5 20], 'sinr');
color_map = rfprop.internal.Validators.validateColorMap(input_parameters, 'sinr');
transparency = 0.4;
show_legend = true;
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

image_size = rfprop.internal.Validators.validateImageSize(...
    gridSize, max_image_resolution_factor, max_image_size, results, 'sinr');

%%

if site_viewer_was_closed(viewer)
    return
end

visual_type = 'sinr';
propagation_data = propagationData(datalats, datalons, ...
    'Name', message('shared_channel:rfprop:CoveragePropagationDataTitle').getString, ...
    'Power', data(:));
propagation_data = propagation_data.setContourProperties(txs_latlon(:,1),txs_latlon(:,2),max_range,image_size);
contour_args = {'Type', visual_type, ...
    'Map', viewer, ...
    'Levels', data(:), ...
    'Transparency', transparency, ...
    'ShowLegend', show_legend, ...
    'ImageSize', image_size, ...
    'ValidateColorConflicts', false,...
    'ColorLimits', color_limit, ...
    'Colormap', color_map};
contour(propagation_data, contour_args{:});

viewer.hideBusyMessage;

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

function contourmap(transmitters, lats, longitudes, data, visual_type, varargin)

parameters = inputParser;
parameters.addParameter('Animation', '');
parameters.addParameter('Levels', []);
parameters.addParameter('SaturateColorFloor', false);
parameters.addParameter('ImageSize', [500 500]);
parameters.addParameter('MaxRange', 30000);
parameters.addParameter('Colormap', 'jet');
parameters.addParameter('Colors', []);
parameters.addParameter('ColorLimits', [120 5]);
parameters.addParameter('Transparency', 0.4);
parameters.addParameter('ShowLegend', true);
parameters.addParameter('LegendTitle', '');
parameters.addParameter('Map', []);
parameters.addParameter('AntennaSiteCoordinates', []);
parameters.parse(varargin{:});

animation = parameters.Results.Animation;
levels = parameters.Results.Levels;
saturate_floor = parameters.Results.SaturateColorFloor;
image_size = parameters.Results.ImageSize;
max_range = parameters.Results.MaxRange;
color_mmap = parameters.Results.Colormap;
colors = parameters.Results.Colors;
color_limit = parameters.Results.ColorLimits;
transparency = parameters.Results.Transparency;
show_legend = parameters.Results.ShowLegend;
legend_title = parameters.Results.LegendTitle;
map = rfprop.internal.Validators.validateMap(parameters, 'contourmap');

[longitude_min, longitude_max] = bounds(longitudes);
[latmin,latmax] = bounds(lats);
imlonsv = linspace(longitude_min,longitude_max,image_size(2));
imlatsv = linspace(latmin,latmax,image_size(1));
[image_lons, image_lats] = meshgrid(imlonsv,imlatsv);
image_lons = image_lons(:);
image_lats = image_lats(:);

txs_coordinates = rfprop.internal.Validators.validateAntennaSiteCoordinates(...
    parameters.Results.AntennaSiteCoordinates, transmitters, map, 'contourmap');
txs_latlon = txs_coordinates.LatitudeLongitude;

grid_color = nan(numel(image_lons), numel(transmitters));
for tx_ind = 1:numel(transmitters)
    txlatlon = txs_latlon(tx_ind,:);
    grid_color(:,tx_ind) = rfprop.internal.MapUtils.greatCircleDistance(...
        txlatlon(1), txlatlon(2), image_lats, image_lons);
end
is_in_range = any(grid_color <= max_range,2);

if isequal(size(data), image_size)
    image_color_data = flipud(data);
    data = data(:);
else
    data = data(:);
    F = scatteredInterpolant(longitudes,lats,data,'natural');
    image_color_data = nan(image_size);
    image_color_data(is_in_range) = F(image_lons(is_in_range),image_lats(is_in_range));
    image_color_data = flipud(image_color_data);
end

data_levels = sort(levels);
max_bin = max(max(data_levels(:)),max(data)) + 1;
bins = [data_levels; max_bin];
if saturate_floor
    data_levels = [data_levels(1); data_levels];
    bins = [-Inf; bins];
end
image_color_data = discretize(image_color_data,bins,data_levels);

if siteViewerWasClosed(map)
    return
end
if isempty(image_color_data) || all(isnan(image_color_data(:)))
    warning(message('shared_channel:rfprop:ContourmapNoDataArea'));
    removeContourMap(transmitters, map);
    return
end

if ~show_legend
    legend_title = '';
end

use_colors = ~isempty(colors);
[image_RGB, image_alpha, legend_colors, legend_color_values] = ...
    imageRGBData(image_color_data, use_colors, colors, color_mmap, color_limit, levels, show_legend);

file_location = [tempname, '.png'];
imwrite(image_RGB, file_location, 'Alpha', image_alpha);
map.addTempFile(file_location);

number_of_tx = numel(transmitters);
ids = cell(1, number_of_tx);
for k = 1:number_of_tx
    ids{k} = transmitters(k).Name;
end
image_url = get_resource_url(file_location, ['contourimage' ids{1}]);

if use_colors
    color_data = struct('Levels',levels,'Colors',colors);
else
    color_data = struct('Colormap',color_mmap,'ColorLimits',color_limit);
end
data = struct(...
    'IDs', {ids}, ...
    'CornerLocations', {{[latmin, longitude_min], [latmax, longitude_max]}}, ...
    'ImageURL', {image_url}, ...
    'Transparency', {transparency}, ...
    'ShowLegend', show_legend, ...
    'LegendTitle', legend_title, ...
    'LegendColors', legend_colors, ...
    'LegendColorValues', legend_color_values, ...
    'Animation', animation, ...
    'EnableWindowLaunch', true);
if siteViewerWasClosed(map)
    return
end
map.image(visual_type, color_data, data);
end

function wasClosed = siteViewerWasClosed(viewer)

wasClosed = viewer.LaunchWebWindow && ~viewer.Visible;
end

function [image_RGB, image_alpha, legend_colors, legend_color_values] = imageRGBData(image_color_data, use_colors, colors, color_map, color_limit, strengths, show_legend)

    legend_colors = string([]);
    legend_color_values = string([]);

    if use_colors
        red = zeros(size(image_color_data));
        green = red;
        blue = red;

        number_of_colors = size(colors, 1);
        color_index = 1;
        for k = 1:numel(strengths)
            level_index = (image_color_data == strengths(k));
            color = colors(color_index,:);
            red(level_index) = color(1);
            green(level_index) = color(2);
            blue(level_index) = color(3);
            color_index = color_index + 1;
            if (color_index > number_of_colors)
                color_index = 1;
            end
            if show_legend
                legend_colors(end+1) = rfprop.internal.ColorUtils.rgb2css(color);
                color_strength = strengths(k);
                if (floor(color_strength) == color_strength)
                    number_of_digits = 0; 
                else
                    number_of_digits = 1;
                end
                legend_color_values(end+1) = mat2str(round(color_strength, number_of_digits));
            end
        end

        if show_legend
            [~,legend_index] = sort(strengths,'descend');
            legend_colors = legend_colors(legend_index);
            legend_color_values = legend_color_values(legend_index);
        end

        image_RGB = cat(3, red, green, blue);
    else
        image_RGB = rfprop.internal.ColorUtils.colorcode(image_color_data, color_map, color_limit);
        if show_legend
            [legend_colors, legend_color_values] = rfprop.internal.ColorUtils.colormaplegend(color_map, color_limit);
        end
    end

    image_alpha = ones(size(image_RGB,1), size(image_RGB,2));
    image_alpha(isnan(image_color_data)) = 0;
end

function [url] = get_resource_url(file_location, name)
    path_names = split(file_location, '\');
    url = ['/static/', name,'/', path_names(end)];
    url = strjoin(url, '');
end

function icons = get_icons(transmitters)
    icons = strings(1, length(transmitters));
    root_path = 'pins/';
    
    for i = 1:length(transmitters)
        name = transmitters(i).Name;
        if contains(name, 'coverage')
            type = 'coverage.png';
        elseif contains(name, 'blind')
            type = 'blind.png';
        elseif contains(name, 'hotspot')
            type = 'hotspot.png';
        else
            type = 'uma.png';
        end
        icons(i) = strcat(root_path, type);
    end
end