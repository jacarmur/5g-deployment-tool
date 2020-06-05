clear all
close all

%% Configuration

DOWNLOAD_MAP = true;
FILTER_CELLS_BY_COMPANY = true;
NUMBER_OF_RX = 5;
TX_POWER_IN_WATTS = 40;
NUMBER_OF_CHANNELS = 1;
COMPANY_ID = 1; % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)

best_sinr_score = 9e9;

%%
UMA_TX_POWER = 40; % Watts = 49 dBm
UMI_TX_POWER = 10; % Watts = 35 dBm
UMA_FREQUENCY = 1.6e9;
UMI_FREQUENCY = 15e9;
INDIVIDUAL_CHANNEL = 1000e6;

%% Frequencies and bands

frequency = containers.Map;
frequency('3') = 1800e6;
frequency('20') = 800e6;
frequency('7') = 2600e6;
frequency('8') = 900e6;

%% Map and phone cells - API connector

lat_min = 37.1463;
lon_min = -3.6097;
lat_max = 37.1597;
lon_max = -3.5875;

lat_min = 37.1473;
lon_min = -3.6097;
lat_max = 37.1647;
lon_max = -3.5875;

coordinates_bbox = location_bbox(lat_min, lat_max, lon_min, lon_max);

bbox_map = coordinates_bbox.get_maps_bbox_string();
if (DOWNLOAD_MAP)
    download_buildings_from_openstreetmap(bbox_map);
end
map = siteviewer('Buildings', 'downloaded_map2.osm');

bbox_cells = coordinates_bbox.get_cells_bbox_string();
phone_cells = get_cells_from_opensignal(bbox_cells);

%% Filter cells if needed

if (FILTER_CELLS_BY_COMPANY)
    selected_phone_cells = filter_cells_by_phone_company(phone_cells, COMPANY_ID); % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)
else
    selected_phone_cells = phone_cells.cells;
end

%% Transmitters generation

offset = load_offset_from_optimization_file();
[uma_latitudes, uma_longitudes] = get_coordinates_from_cells(selected_phone_cells);
% Comprobar dos veces solamente con offsets aleatorios
uma_transmitters = get_transmitters_from_coordinates(uma_latitudes, uma_longitudes, UMA_TX_POWER, UMA_FREQUENCY, offset);

[data_latitudes, data_longitudes, uma_grid_size, uma_sinr_data] = calculate_sinr_values_map(uma_transmitters, coordinates_bbox);

plot_values_map(uma_transmitters, data_latitudes, data_longitudes, uma_grid_size, uma_sinr_data);

%%
number_of_receivers = 5000;
[social_attractors_latitudes, social_attractors_longitudes, ...
    social_attractors_weighting] = read_buildings_file();
[receivers_latitudes, receivers_longitudes] = generate_receivers_from_social_attractors(...
    social_attractors_latitudes, social_attractors_longitudes, ...
    social_attractors_weighting, number_of_receivers);

receivers = rxsite(...
    'Latitude', receivers_latitudes, ...
    'Longitude', receivers_longitudes, ...
    'AntennaHeight', 1.5);
show(receivers);
%%
best_sinr_data_reached = false;
best_sinr_data = uma_sinr_data;
umi_transmitters = [];
while ~best_sinr_data_reached
    [umi_cell_latitudes, umi_cell_longitudes] = ...
        calculate_small_cells_coords(best_sinr_data, ...
        data_latitudes, data_longitudes);
    umi_cell_angles = generate_random_cell_angles(length(umi_cell_latitudes));
    umi_transmitters = [umi_transmitters get_transmitters_from_coordinates(umi_cell_latitudes, umi_cell_longitudes, UMI_TX_POWER, UMI_FREQUENCY, umi_cell_angles)];
    [umi_data_latitudes, umi_data_longitudes, best_umi_grid_size, umi_sinr_data] = calculate_sinr_values_map([umi_transmitters uma_transmitters], coordinates_bbox);
    best_sinr_data = merge_sinr_data(uma_sinr_data, umi_sinr_data);
    best_sinr_data_reached = ~ismember(1, best_sinr_data < 0);
end
umi_map = siteviewer('Buildings', 'downloaded_map2.osm');
plot_values_map(umi_transmitters, umi_data_latitudes, umi_data_longitudes, best_umi_grid_size, umi_sinr_data);

final_map = siteviewer('Buildings', 'downloaded_map2.osm');
plot_values_map([uma_transmitters umi_transmitters], data_latitudes, data_longitudes, best_umi_grid_size, best_sinr_data);

% sinr_matrix = get_sinr_matrix_for_all_the_transmitters(receivers, uma_transmitters);
% power_matrix = get_power_matrix_for_all_the_transmitters(receivers, uma_transmitters);

% ver como afecta reuso
% demanda definida por el usuario, anchos de banda grandes
% optimizacion
