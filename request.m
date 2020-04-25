clear all
close all

%% Configuration

DOWNLOAD_MAP = true;
FILTER_CELLS_BY_COMPANY = true;
NUMBER_OF_RX = 5;
TX_POWER_IN_WATTS = 15;
NUMBER_OF_CHANNELS = 5;
COMPANY_ID = 1; % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)

best_sinr_score = 9e9;

%%
UMA_TX_POWER = 6; % Watts = 49 dBm
UMI_TX_POWER = 10; % Watts = 35 dBm
UMA_FREQUENCY = 1.6e9;
UMI_FREQUENCY = 15e9;
INDIVIDUAL_CHANNEL = 10e6;

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

for offset=0:10:60
[uma_latitudes, uma_longitudes] = get_coordinates_from_cells(selected_phone_cells);
% Comprobar dos veces solamente con offsets aleatorios
transmitters = get_transmitters_from_coordinates(uma_latitudes, uma_longitudes, UMA_TX_POWER, UMA_FREQUENCY, INDIVIDUAL_CHANNEL, offset);

[best_data_latitudes, best_data_longitudes, grid_size, best_sinr_data] = calculate_sinr_values_map(transmitters, coordinates_bbox);
current_sinr_points = length(find(best_sinr_data<5));

    if current_sinr_points < best_sinr_score
        best_data_latitudes = best_data_latitudes;
        best_data_longitudes = best_data_longitudes;
        best_grid_size = grid_size;
        best_sinr_data = best_sinr_data; 
        best_sinr_score = current_sinr_points;
        best_offset = offset;
    end
end
plot_values_map(transmitters, best_data_latitudes, best_data_longitudes, best_grid_size, best_sinr_data);

best_sinr_data_reached = false;
umi_transmitters = [];
while false
    [small_cell_latitudes, small_cell_longitudes] = ...
        calculate_small_cells_coords(best_sinr_data, ...
        best_data_latitudes, best_data_longitudes);

    umi_transmitters = [umi_transmitters get_transmitters_from_coordinates(small_cell_latitudes, small_cell_longitudes, UMI_TX_POWER, UMI_FREQUENCY, INDIVIDUAL_CHANNEL, best_offset)];
    [best_data_latitudes, best_data_longitudes, grid_size, best_sinr_data] = calculate_sinr_values_map([transmitters umi_transmitters], coordinates_bbox);
    best_sinr_data_reached = ~ismember(1, best_sinr_data < 0);
end
final_map = siteviewer('Buildings', 'downloaded_map2.osm');
plot_values_map([transmitters umi_transmitters], best_data_latitudes, best_data_longitudes, grid_size, best_sinr_data);

% sinr_matrix = get_sinr_matrix_for_all_the_transmitters(receiver, transmitters);
% power_matrix = get_power_matrix_for_all_the_transmitters(receiver, transmitters);

% ver como afecta reuso
% demanda definida por el usuario, anchos de banda grandes
% optimizacion
