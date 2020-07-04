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
on_forced_exit = rfprop.internal.onExit(@()hideBusyMessage(viewer));
viewer.showBusyMessage(message('shared_channel:rfprop:SINRMapBusyMessage').getString);

viewer = rfprop.internal.Validators.validateMap(input_parameters, 'sinr');

%%
animation = rfprop.internal.Validators.validateGraphicsControls(input_parameters, 'sinr');
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
visual_type = 'sinr';
color_data = struct('Colormap',color_map,'ColorLimits',color_limit);

image_size = rfprop.internal.Validators.validateImageSize(...
    gridSize, max_image_resolution_factor, max_image_size, results, 'sinr');

%%

if site_viewer_was_closed(viewer)
    return
end

visual_type = 'sinr';
values = (-5:20)';
pd = propagationData(datalats, datalons, ...
    'Name', message('shared_channel:rfprop:CoveragePropagationDataTitle').getString, ...
    'Power', data(:));
pd = pd.setContourProperties(txs_latlon(:,1),txs_latlon(:,2),max_range,image_size);
contourArgs = {'Type', visual_type, ...
    'Map', viewer, ...
    'Levels', data(:), ...
    'Transparency', transparency, ...
    'ShowLegend', show_legend, ...
    'ImageSize', image_size, ...
    'ValidateColorConflicts', false,...
    'ColorLimits', color_limit, ...
    'Colormap', color_map};
contour(pd, contourArgs{:});

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

function contourmap(txs, lats, lons, data, visualType, varargin)
%contourmap   Display contour map

%   Copyright 2017-2019 The MathWorks, Inc.

p = inputParser;
p.addParameter('Animation', '');
p.addParameter('Levels', []);
p.addParameter('SaturateColorFloor', false);
p.addParameter('ImageSize', [500 500]);
p.addParameter('MaxRange', 30000);
p.addParameter('Colormap', 'jet');
p.addParameter('Colors', []);
p.addParameter('ColorLimits', [120 5]);
p.addParameter('Transparency', 0.4);
p.addParameter('ShowLegend', true);
p.addParameter('LegendTitle', '');
p.addParameter('Map', []);
p.addParameter('AntennaSiteCoordinates', []);
p.parse(varargin{:});

% Get parameters, leaving validation to caller
animation = p.Results.Animation;
levels = p.Results.Levels;
saturateFloor = p.Results.SaturateColorFloor;
imageSize = p.Results.ImageSize;
maxrange = p.Results.MaxRange;
cmap = p.Results.Colormap;
colors = p.Results.Colors;
clim = p.Results.ColorLimits;
transparency = p.Results.Transparency;
showLegend = p.Results.ShowLegend;
legendTitle = p.Results.LegendTitle;
viewer = rfprop.internal.Validators.validateMap(p, 'contourmap');

% Generate lat/lon grid for contour map image
[lonmin,lonmax] = bounds(lons);
[latmin,latmax] = bounds(lats);
imlonsv = linspace(lonmin,lonmax,imageSize(2));
imlatsv = linspace(latmin,latmax,imageSize(1));
[imlons,imlats] = meshgrid(imlonsv,imlatsv);
imlons = imlons(:);
imlats = imlats(:);

% Get site coordinates
txsCoords = rfprop.internal.Validators.validateAntennaSiteCoordinates(...
    p.Results.AntennaSiteCoordinates, txs, viewer, 'contourmap');
txslatlon = txsCoords.LatitudeLongitude;

% Find grid locations that are within range of any transmitter site
gc = nan(numel(imlons),numel(txs));
for txInd = 1:numel(txs)
    txlatlon = txslatlon(txInd,:);
    gc(:,txInd) = rfprop.internal.MapUtils.greatCircleDistance(...
        txlatlon(1), txlatlon(2), imlats, imlons);
end
isInRange = any(gc <= maxrange,2);

if isequal(size(data), imageSize)
    % If input data size is the same as ImageSize, perform no interpolation
    imageCData = flipud(data);
    data = data(:);
else
    % Create image data grid using interpolation. Query for locations within
    % range of any transmitter site, or otherwise use NaN. For preference of
    % 'natural' method over 'linear', see https://blogs.mathworks.com/loren/2015/07/01/natural-neighbor-a-superb-interpolation-method/
    data = data(:);
    F = scatteredInterpolant(lons,lats,data,'natural');
    imageCData = nan(imageSize);
    imageCData(isInRange) = F(imlons(isInRange),imlats(isInRange));
    imageCData = flipud(imageCData); % Start data columns from north instead of south
end

% Discretize image data so that each value is replaced by the corresponding
% contour level value or else NaN if it is below the minimum value
datalevels = sort(levels);
maxBin = max(max(datalevels(:)),max(data)) + 1; % Need max bin edge to include all values
bins = [datalevels; maxBin];
if saturateFloor % Make all values below lowest level part of that level
    datalevels = [datalevels(1); datalevels];
    bins = [-Inf; bins];
end
imageCData = discretize(imageCData,bins,datalevels);

% Return early if no data to show, which likely means the minimum data
% value specified cannot be met
if siteViewerWasClosed(viewer)
    return
end
if isempty(imageCData) || all(isnan(imageCData(:)))
    warning(message('shared_channel:rfprop:ContourmapNoDataArea'));
    removeContourMap(txs, viewer);
    return
end

% Create image data matrix, mapping color data to RGB values
if ~showLegend
    legendTitle = '';
end
useColors = ~isempty(colors);
[imageRGB, imageAlpha, legendColors, legendColorValues] = ...
    imageRGBData(imageCData, useColors, colors, cmap, clim, levels, showLegend);

% Create temp image file and mark for deletion on close of Site Viewer
fileLoc = [tempname, '.png'];
imwrite(imageRGB, fileLoc, 'Alpha', imageAlpha);
viewer.addTempFile(fileLoc);

% Get image file URL. Use first site's ID to generate a unique URL, which
% is okay since a site cannot have multiple coverage maps.
numTx = numel(txs);
ids = cell(1, numTx);
for k = 1:numTx
    ids{k} = txs(k).Name;
end
imageURL = get_resource_url(fileLoc, ['contourimage' ids{1}]);

% Overlay contour map image on map
if useColors
    colorData = struct('Levels',levels,'Colors',colors);
else
    colorData = struct('Colormap',cmap,'ColorLimits',clim);
end
data = struct(...
    'IDs', {ids}, ...
    'CornerLocations', {{[latmin, lonmin], [latmax, lonmax]}}, ...
    'ImageURL', {imageURL}, ...
    'Transparency', {transparency}, ...
    'ShowLegend', showLegend, ...
    'LegendTitle', legendTitle, ...
    'LegendColors', legendColors, ...
    'LegendColorValues', legendColorValues, ...
    'Animation', animation, ...
    'EnableWindowLaunch', true);
if siteViewerWasClosed(viewer)
    return % Abort if Site Viewer has been closed (test before image overlay)
end
viewer.image(visualType, colorData, data);
end

function wasClosed = siteViewerWasClosed(viewer)

wasClosed = viewer.LaunchWebWindow && ~viewer.Visible;
end

function [imgRGB, imgAlpha, legendColors, legendColorValues] = imageRGBData(imageCData, useColors, colors, cmap, clim, strengths, showLegend)
% Return image RGB and alpha matrices

legendColors = string([]);
legendColorValues = string([]);

% Use Colors if user specified or if single signal level and no Colormap
% specified
if useColors
    % Initialize image RGB matrices
    imgR = zeros(size(imageCData));
    imgG = imgR;
    imgB = imgR;
    
    % Color each user-specified level in the image matrix
    numColors = size(colors, 1);
    colorInd = 1;
    for k = 1:numel(strengths)
        % Get indices in image matching level
        levelInd = (imageCData == strengths(k));
        
        % Get level's color and assign in image RGB matrices
        color = colors(colorInd,:);
        imgR(levelInd) = color(1);
        imgG(levelInd) = color(2);
        imgB(levelInd) = color(3);
        
        % Cycle through colors
        colorInd = colorInd + 1;
        if (colorInd > numColors)
            colorInd = 1;
        end
        
        % Grow legend values
        if showLegend
            legendColors(end+1) = rfprop.internal.ColorUtils.rgb2css(color); %#ok<*AGROW>
            colorStrength = strengths(k);
            if (floor(colorStrength) == colorStrength)
                numDigits = 0; % Show integer value
            else
                numDigits = 1; % Show one decimal place
            end
            legendColorValues(end+1) = mat2str(round(colorStrength,numDigits));
        end
    end
    
    % Sort legend values so that legend descends from top to bottom
    if showLegend
        [~,legendInd] = sort(strengths,'descend');
        legendColors = legendColors(legendInd);
        legendColorValues = legendColorValues(legendInd);
    end
    
    % Get RGB matrix
    imgRGB = cat(3, imgR, imgG, imgB);
else
    imgRGB = rfprop.internal.ColorUtils.colorcode(imageCData, cmap, clim);
    if showLegend
        [legendColors, legendColorValues] = rfprop.internal.ColorUtils.colormaplegend(cmap, clim);
    end
end

% Create transparency matrix (make clear where data is NaN)
imgAlpha = ones(size(imgRGB,1),size(imgRGB,2));
imgAlpha(isnan(imageCData)) = 0;
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