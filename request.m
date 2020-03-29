%close (map)
clear all
close all

%% Configuration

DOWNLOAD_MAP = false;
FILTER_CELLS_BY_COMPANY = true;
NUMBER_OF_RX = 5;
TX_POWER_IN_WATTS = 15;
NUMBER_OF_CHANNELS = 5;

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
    download_building_from_openstreetmap(bbox_map);
end
map = siteviewer('Buildings', 'downloaded_map2.osm');

bbox_cells = coordinates_bbox.get_cells_bbox_string();
phone_cells = get_cells_from_opensignal(bbox_cells);

%% Filter cells if needed

if (FILTER_CELLS_BY_COMPANY)
    selected_phone_cells = filter_cells_by_phone_company(phone_cells, 1); % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)
else
    selected_phone_cells = phone_cells;
end

%% Transmitters generation

transmitters = get_transmitters_from_cells(selected_phone_cells, frequency, TX_POWER_IN_WATTS, NUMBER_OF_CHANNELS);
for i = 1:length(transmitters)
    show(transmitters(i));
end

%% Rx 

for rx_index = 1:NUMBER_OF_RX
    variation1 = (rand()-0.5)*0.01;
    variation2 = (rand()-0.5)*0.01;
    rx_lat = (lat_max + lat_min)/2 + variation1;
    rx_lon = (lon_max + lon_min)/2 + variation2;
    receivers(rx_index) = rxsite("Name","Receiver "+rx_index, ...
        "Latitude",rx_lat, ...
        "Longitude",rx_lon, ...
        "AntennaHeight",1);

    show(receivers(rx_index));
end
sinr_map = calculate_sinr_values_map(transmitters, coordinates_bbox);
plot_values_map(sinr_map);
sinr_matrix = get_sinr_matrix_for_all_the_transmitters(receivers, transmitters);
power_matrix = get_power_matrix_for_all_the_transmitters(receivers, transmitters);

%% TODO LIST
% Asignacion de frecuencias segun tecnologia
% Algoritmo de asignacion de canales / ancho de banda
% Hacer trisectorial, desfase, optimizar
% SINR numerico para todo mapa de calor
% -----
% Revisar 5G en sitios ya existentes -> no existe una DB fiable
