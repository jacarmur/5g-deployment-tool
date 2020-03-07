clear all
close all

DOWNLOAD_MAP = false;
FILTER_CELLS_BY_COMPANY = true;

%% Frequencies and bands

frequency = containers.Map;
frequency('3') = 1800e6;
frequency('20') = 800e6;
frequency('7') = 2600e6;
frequency('8') = 900e6;

%%

lat_min = 37.1463;
lon_min = -3.6097;
lat_max = 37.1597;
lon_max = -3.5875;
% lat_min = 40.4131699;
% lon_min = -3.6830699;
% lat_max = 40.42317;
% lon_max = -3.6731;
%-3.6297%2C37.1683%2C-3.5425%2C37.1907

bbox_map = coordinates_to_string(lon_min, lat_min, lon_max, lat_max);
if (DOWNLOAD_MAP)
    download_building_from_openstreetmap(bbox_map);
end
map = siteviewer('Buildings', 'downloaded_map2.osm');

%%
bbox_cells = coordinates_to_string(lat_min, lon_min, lat_max, lon_max);
phone_cells = get_cells_from_opensignal(bbox_cells);

%%

if (FILTER_CELLS_BY_COMPANY)
    selected_phone_cells = filter_cells_by_phone_company(phone_cells, 1); % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)
else
    selected_phone_cells = phone_cells;
end
%%

transmitters = get_transmitters_from_cells(selected_phone_cells, frequency);
for i = 1:length(transmitters)
    show(transmitters(i));
end

rx_lat = (lat_max + lat_min)/2;
rx_lon = (lon_max + lon_min)/2;
rx_st = rxsite("Name","Small cell receiver", ...
    "Latitude",rx_lat, ...
    "Longitude",rx_lon, ...
    "AntennaHeight",1);

for i=1:length(selected_phone_cells)
    raytrace(transmitters(i),rx_st,"NumReflections", 1, ...
    "Type","pathloss", ...
    "ColorLimits",[80 130])
end

individual_snr = zeros(1, length(selected_phone_cells));
for i=1:length(selected_phone_cells)
    individual_snr(i) = sinr(rx_st, transmitters(i));
end

sinr(transmitters(10));

%plot(individual_snr);

% Asignacion de frecuencias segun tecnologia
% Algoritmo de asignacion de canales / ancho de banda
% Hacer trisectorial, desfase, optimizar
% SINR numerico para todo mapa de calor
% -----
% Revisar 5G en sitios ya existentes -> no existe una DB fiable
