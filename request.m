clear all
close all

lat_min = 37.1463;
lon_min = -3.6097;
lat_max = 37.1597;
lon_max = -3.5875;
lat_min = 40.4131699;
lon_min = -3.6830699;
lat_max = 40.42317;
lon_max = -3.6731;
%-3.6297%2C37.1683%2C-3.5425%2C37.1907

bbox_map = coordinates_to_string(lon_min, lat_min, lon_max, lat_max);
map_uri = 'https://api.openstreetmap.org/api/0.6/map';
%todo: bbox a trozos
map_file = websave('downloaded_map2.osm', map_uri, 'bbox', bbox_map);
%map_file = strrep(map_file, '%3C', '');
%fid = fopen('downloaded_map2.osm','wt');
%fprintf(fid, native2unicode(map_file));
%fclose(fid);
map = siteviewer('Buildings', 'downloaded_map2.osm');
%map = siteviewer('Buildings', 'map_1.osm');

headerField = matlab.net.http.field.ContentTypeField('application/json; charset=utf-8');
key_value = '3eac6f07ea72c7';
radio_value = 'LTE';
format_value = 'json';
bbox_cells = coordinates_to_string(lat_min, lon_min, lat_max, lon_max);
cells_uri = 'http://opencellid.org/cell/getInArea';

%phone_cells = webread(cells_uri, 'key', key_value, 'radio', radio_value, 'format', format_value, 'BBOX', bbox_cells);
phone_cells = webread(cells_uri, 'key', key_value, 'format', format_value, 'BBOX', bbox_cells);

selected_phone_mnc_index = vertcat(phone_cells.cells.mnc) == 1; % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)

%select the cells with the desired mnc
%selected_phone_cells = [];
index = 1;
for i = 1:phone_cells.count
    if selected_phone_mnc_index(i)
        selected_phone_cells(index) = phone_cells.cells(i);
        index = index+1;
    end
end

for i = 1:length(selected_phone_cells)
    lat = selected_phone_cells(i).lat;
    lon = selected_phone_cells(i).lon;
    
    transmitter(i) = txsite("Name","Small cell transmitter", ...
    "Latitude",lat, ...
    "Longitude",lon, ...
    "AntennaHeight",10, ...
    "TransmitterPower",5, ...
    "TransmitterFrequency",20e9);

    show(transmitter(i));
end

rx_lat = (lat_max + lat_min)/2;
rx_lon = (lon_max + lon_min)/2;
rx_st = rxsite("Name","Small cell receiver", ...
    "Latitude",rx_lat, ...
    "Longitude",rx_lon, ...
    "AntennaHeight",1);

for i=1:length(selected_phone_cells)
    raytrace(transmitter(i),rx_st,"NumReflections", 1, ...
    "Type","pathloss", ...
    "ColorLimits",[80 130])
end

individual_snr = zeros(1, length(selected_phone_cells));
for i=1:length(selected_phone_cells)
    individual_snr(i) = sinr(rx_st, transmitter(i));
end

%sinr(transmitter(50));

plot(individual_snr);
% Asignacion de frecuencias segun tecnologia
% Algoritmo de asignacion de canales / ancho de banda
% Hacer trisectorial, desfase, optimizar
% SINR numerico para todo mapa de calor
% Revisar 5G en sitios ya existentes
