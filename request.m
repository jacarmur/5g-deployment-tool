clear all
close all

%% Configuration

DOWNLOAD_MAP = false;
FILTER_CELLS_BY_COMPANY = true;
NUMBER_OF_RX = 5;
TX_POWER_IN_WATTS = 15;
NUMBER_OF_CHANNELS = 5;
COMPANY_ID = 1; % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)

best_sinr_points = 9e9;

%%
UMA_TX_POWER = 15; % Watts = 49 dBm
UMI_TX_POWER = 3.16; % Watts = 35 dBm
UMA_FREQUENCY = 1.8e9;
UMI_FREQUENCY = 18e9;
INDIVIDUAL_CHANNEL = 50e6;

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
    selected_phone_cells = phone_cells;
end

%% Transmitters generation

for offset=0:10:40
[uma_latitudes, uma_longitudes] = get_coordinates_from_cells(selected_phone_cells);
transmitters = get_transmitters_from_coordinates(uma_latitudes, uma_longitudes, UMA_TX_POWER, UMA_FREQUENCY, INDIVIDUAL_CHANNEL, offset);
% for i = 1:length(transmitters)
%     show(transmitters(i));
% end

%% Rx 

% for rx_index = 1:NUMBER_OF_RX
%     variation1 = (rand()-0.5)*0.01;
%     variation2 = (rand()-0.5)*0.01;
%     rx_lat = (lat_max + lat_min)/2 + variation1;
%     rx_lon = (lon_max + lon_min)/2 + variation2;
%     receivers(rx_index) = rxsite("Name","Receiver "+rx_index, ...
%         "Latitude",rx_lat, ...
%         "Longitude",rx_lon, ...
%         "AntennaHeight",1);
% 
%     show(receivers(rx_index));
% end
[data_latitudes, data_longitudes, grid_size, sinr_data] = calculate_sinr_values_map(transmitters, coordinates_bbox);
current_sinr_points = length(find(sinr_data<5));

    if current_sinr_points < best_sinr_points
        best_data_latitudes = data_latitudes;
        best_data_longitudes = data_longitudes;
        best_grid_size = grid_size;
        best_sinr_data = sinr_data;
        best_sinr_points = current_sinr_points;
    end
end
plot_values_map(transmitters, best_data_latitudes, best_data_longitudes, best_grid_size, best_sinr_data);

sinr_matrix = get_sinr_matrix_for_all_the_transmitters(receivers, transmitters);
%power_matrix = get_power_matrix_for_all_the_transmitters(receivers, transmitters);

%% TODO LIST
% Asignacion de frecuencias segun tecnologia
% Algoritmo de asignacion de canales / ancho de banda
% Hacer trisectorial, desfase, optimizar
% SINR numerico para todo mapa de calor
% -----
% Revisar 5G en sitios ya existentes -> no existe una DB fiable
