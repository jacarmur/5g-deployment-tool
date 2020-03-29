function [datalats, datalons, data] = calculate_sinr_values_map(transmitters, coordinates_bbox, varargin)

% Validate site
validateattributes(transmitters,{'txsite'},{'nonempty'},'sinr','',1);

% Add parameters
p = inputParser;
if mod(numel(varargin),2) % Odd number of inputs
    % Validator function is necessary for inputParser to allow string
    % option instead of treating it like parameter name
    p.addOptional('PropagationModel', [], @(x)ischar(x)||isstring(x)||isa(x,'rfprop.PropagationModel'));
else
    p.addParameter('PropagationModel', []);
end
p.addParameter('SignalSource', 'strongest');
p.addParameter('Values', -5:20);
p.addParameter('Resolution', 'auto');
p.addParameter('ReceiverGain', 2.1);
p.addParameter('ReceiverAntennaHeight', 1);
p.addParameter('ReceiverNoisePower', -107);
p.addParameter('Animation', '');
p.addParameter('MaxRange', []);
p.addParameter('Colormap', 'jet');
p.addParameter('ColorLimits', []);
p.addParameter('Transparency', 0.4);
p.addParameter('ShowLegend', true);
p.addParameter('ReceiverLocationsLayout', []);
p.addParameter('MaxImageResolutionFactor', 5);
p.addParameter('RadialResolutionFactor', 2);
p.addParameter('Map', []);
p.parse(varargin{:});

% Get Site Viewer and validate web graphics
viewer = rfprop.internal.Validators.validateMap(p, 'sinr');
viewer.validateWebGraphicsSupport;
isViewerInitiallyVisible = viewer.Visible;

% Create vector array of all txs
sigSource = validateSignalSource(p);
transmitters = transmitters(:);
if isa(sigSource,'txsite')
    if ~ismember(sigSource,transmitters)
        transmitters = [transmitters; sigSource];
    end
end
numTx = numel(transmitters);

% Get site coordinates
txsCoords = rfprop.internal.AntennaSiteCoordinates.createFromAntennaSites(transmitters, viewer);
txslatlon = transmitters.location;

% Validate parameters
animation = rfprop.internal.Validators.validateGraphicsControls(p, 'sinr');
values = validateValues(p);
clim = rfprop.internal.Validators.validateColorLimits(p, [-5 20], 'sinr');
cmap = rfprop.internal.Validators.validateColorMap(p, 'sinr');
transparency = rfprop.internal.Validators.validateTransparency(p, 'sinr');
showLegend = rfprop.internal.Validators.validateShowLegend(p, 'sinr');
pm = rfprop.internal.Validators.validatePropagationModel(p, viewer, 'sinr');
rxGain = rfprop.internal.Validators.validateReceiverGain(p, 'sinr');
rxAntennaHeight = rfprop.internal.Validators.validateReceiverAntennaHeight(p, 'sinr');
noisePower = validateReceiverNoisePower(p);

% Validate dependent parameters
if ismember('MaxRange', p.UsingDefaults)
    maxrange = rfprop.internal.Validators.defaultMaxRange(txslatlon, pm, viewer);
else
    maxrange = rfprop.internal.Validators.validateNumericMaxRange(p.Results.MaxRange, pm, numTx, viewer, 'sinr');
end
[res, isAutoRes] = rfprop.internal.Validators.validateResolution(p, maxrange, 'sinr');
datarange = rfprop.internal.Validators.validateDataRange(txslatlon, maxrange, res, viewer.UseTerrain);
rxLocationsLayout = rfprop.internal.Validators.validateReceiverLocationsLayout(p, pm, txslatlon, 'sinr');
maxImageResFactor = p.Results.MaxImageResolutionFactor;
radialResFactor = p.Results.RadialResolutionFactor;

% Validate visualization type and color data
ids = cell(1, numTx);
for k = 1:numTx
    ids{k} = transmitters(k).Name;
end
visualType = 'sinr';
colorData = struct('Colormap',cmap,'ColorLimits',clim);
viewer.validateImageVisualization(ids, visualType, colorData);

% Generate location grid containing data range from each transmitter site
maxImageSize = viewer.MaxImageSize;
latNorth = coordinates_bbox.maximum_latitude;
latSouth = coordinates_bbox.minimum_latitude;
lonEast = coordinates_bbox.maximum_longitude;
lonWest = coordinates_bbox.minimum_longitude;

[gridlats, gridlons, res] = rfprop.internal.MapUtils.geogrid(...
    latNorth, latSouth, lonEast, lonWest, res, isAutoRes, maxrange, maxImageSize, 'sinr');
gridSize = size(gridlats);

% Compute and validate image size for SINR map
imageSize = rfprop.internal.Validators.validateImageSize(...
    gridSize, maxImageResFactor, maxImageSize, res, 'sinr');

% Trim grid locations to those which are within data range
[datalats, datalons] = rfprop.internal.MapUtils.georange(...
    transmitters, gridlats(:), gridlons(:), datarange, viewer.TerrainSource);

type = 'power';

% Define rxsites at grid locations within data range
rxs = rxsite(...
    'Name', 'internal.sinrsite', ... % Specify to avoid default site naming
    'Latitude', datalats, ...
    'Longitude', datalons, ...
    'AntennaHeight', rxAntennaHeight);

% Compute signal strength at each rxsite in the grid
ss = sigstrength(rxs, transmitters, pm, ...
    'Type', type, ...
    'ReceiverGain', rxGain, ...
    'Map', viewer, ...
    'TransmitterAntennaSiteCoordinates', txsCoords);

% Cache signal strength on site coordinates
txsCoords.addCustomData('SignalStrength', ss);

% Compute SINR at each rxsite in the grid
data = sinr(rxs, transmitters, ...
    'SignalSource', sigSource, ...
    'ReceiverNoisePower', noisePower, ...
    'PropagationModel', pm, ...
    'ReceiverGain', rxGain, ...
    'TransmitterAntennaSiteCoordinates', txsCoords, ...
    'Map', viewer);

% Create contour map
if siteViewerWasClosed(viewer)
    return
end
contourmap(transmitters, datalats, datalons, data, visualType, ...
    'Animation', animation, ...
    'Map', viewer, ...
    'Levels', values, ...
    'ColorLimits', clim, ...
    'Colormap', cmap, ...
    'Transparency', transparency, ...
    'ShowLegend', showLegend, ...
    'ImageSize', imageSize, ...
    'MaxRange', maxrange, ...
    'LegendTitle', message('shared_channel:rfprop:SINRLegendTitle').getString, ...
    'SaturateColorFloor', true, ...
    'AntennaSiteCoordinates', txsCoords);

end

function wasClosed = siteViewerWasClosed(viewer)

wasClosed = viewer.LaunchWebWindow && ~viewer.Visible;
end

function sigsource = validateSignalSource(p)

try
    sigsource = p.Results.SignalSource;
    if ischar(sigsource) || isstring(sigsource)
        sigsource = validatestring(sigsource, {'strongest'}, ...
            'sinr','SignalSource');
    else
        validateattributes(sigsource,{'txsite'}, {'scalar'}, ...
            'sinr','SignalSource');
    end
catch e
    throwAsCaller(e);
end
end

function values = validateValues(p)

try
    values = p.Results.Values;
    validateattributes(values, {'numeric'}, ...
        {'real','finite','nonnan','nonsparse','vector','nonempty'}, 'sinr', 'Values');
    if ~iscolumn(values)
        values = values(:);
    end
    values = double(values);
catch e
    throwAsCaller(e);
end
end

function noisePower =  validateReceiverNoisePower(p)

try
    noisePower = p.Results.ReceiverNoisePower;
    validateattributes(noisePower, {'numeric'}, {'real','finite','nonnan','nonsparse','scalar'}, ...
        'sinr', 'ReceiverNoisePower');
catch e
    throwAsCaller(e);
end
end
