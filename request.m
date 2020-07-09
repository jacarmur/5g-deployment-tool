function [] = request(parameters)
addpath('entities', 'connectors', 'use_cases', 'repositories');

%% Parameters
FILTER_CELLS_BY_COMPANY = parameters.filter_by_company;
COMPANY_ID = str2double(parameters.company); % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)
NUMBER_OF_RECEIVERS = parameters.number_of_receivers;
BW = parameters.individual_bw; % MHz

UMA_TX_POWER = parameters.uma_power; % Watts = 44 dBm
UMI_COVERAGE_TX_POWER = parameters.umi_coverage_power;
UMI_HOTSPOT_TX_POWER = parameters.umi_hotspot_power;
UMI_BLIND_SPOT_TX_POWER = parameters.umi_blind_power;
UMI_ISD = parameters.umi_coverage_isd; % meters

UMA_FREQUENCY = parameters.uma_frequency;
UMI_COVERAGE_FREQUENCY = parameters.umi_coverage_frequency;
UMI_HOTSPOT_FREQUENCY = parameters.umi_hotspot_frequency;
UMI_BLIND_SPOT_FREQUENCY = parameters.umi_blind_frequency;

lat_min = parameters.minimum_latitude;
lon_min = parameters.minimum_longitude;
lat_max = parameters.maximum_latitude;
lon_max = parameters.maximum_longitude;
IS_COVERAGE_MODE = parameters.coverage;
MAX_NUMBER_OF_ATTEMPTS = parameters.max_attempts;
DOWNLOAD_MAP = parameters.download_map_file;

if parameters.longley_rice
    PROPAGATION_MODEL = 'longley-rice';
else
    PROPAGATION_MODEL = 'raytracing-image-method';
end

%% Constants
UMA_NAME = 'uma';
UMI_COVERAGE_NAME = 'umi_coverage';
UMI_HOTSPOT_NAME = 'umi_hotspot';
UMI_BLIND_SPOT_NAME = 'umi_blind_spot';
UMA_ANTENNA = 'sector';
UMI_ANTENNA = 'isotropic';
UMA_HEIGHT = 25; % meters
UMI_HEIGHT = 10; % meters
uma_tx_model = tx_model(UMA_FREQUENCY, UMA_TX_POWER, UMA_ANTENNA, UMA_HEIGHT, UMA_NAME);
umi_coverage_model = tx_model(UMI_COVERAGE_FREQUENCY, UMI_COVERAGE_TX_POWER, UMI_ANTENNA, UMI_HEIGHT, UMI_COVERAGE_NAME);
umi_hotspot_model = tx_model(UMI_HOTSPOT_FREQUENCY, UMI_HOTSPOT_TX_POWER, UMI_ANTENNA, UMI_HEIGHT, UMI_HOTSPOT_NAME);
umi_blind_spot_model = tx_model(UMI_BLIND_SPOT_FREQUENCY, UMI_BLIND_SPOT_TX_POWER, UMI_ANTENNA, UMI_HEIGHT, UMI_BLIND_SPOT_NAME);

%%
disp("Generating map...");
coordinates_bbox = location_bbox(lat_min, lat_max, lon_min, lon_max);

bbox_map = coordinates_bbox.get_maps_bbox_string();
if (DOWNLOAD_MAP)
    download_buildings_from_openstreetmap(bbox_map);
end
map = siteviewer('Buildings', 'map.osm');

disp("Downloading existing cells location...");
bbox_cells = coordinates_bbox.get_cells_bbox_string();
phone_cells = get_cells_from_opensignal(bbox_cells);

%% Filter cells if needed

if (FILTER_CELLS_BY_COMPANY)
    selected_phone_cells = filter_cells_by_phone_company(phone_cells, COMPANY_ID); % Vodafone = 1; Orange = 3; Telefonica = 7 (ver MNC wikipedia)
else
    selected_phone_cells = phone_cells.cells;
end

%% UMA Transmitters generation
disp("Generating UMa layer...");
[uma_latitudes, uma_longitudes] = get_coordinates_from_cells(selected_phone_cells);
uma_transmitters = get_transmitters_from_coordinates(uma_latitudes, uma_longitudes, uma_tx_model);

[data_latitudes, data_longitudes, uma_grid_size, uma_sinr_data] = calculate_sinr_values_map(uma_transmitters, coordinates_bbox, PROPAGATION_MODEL);
%plot_values_map(uma_transmitters, data_latitudes, data_longitudes, uma_grid_size, uma_sinr_data);

%% Users - receivers
disp("Generating receivers...");
if DOWNLOAD_MAP
    social_attractors_coordinates = coordinates_bbox.get_social_attractors_bbox_string();
    system('python main.py ' + social_attractors_coordinates);
else
    system('python main.py');
end

[social_attractors_latitudes, social_attractors_longitudes, ...
    social_attractors_weighting] = read_buildings_file();
[receivers_latitudes, receivers_longitudes] = generate_receivers_from_social_attractors(...
    social_attractors_latitudes, social_attractors_longitudes, ...
    social_attractors_weighting, NUMBER_OF_RECEIVERS, coordinates_bbox);

receivers = rxsite(...
    'Latitude', receivers_latitudes, ...
    'Longitude', receivers_longitudes, ...
    'AntennaHeight', 1.5);

%% UMI blind spot coverage mode
if IS_COVERAGE_MODE
    disp("Computing UMi Layer in coverage of blind spots mode");
    best_sinr_data_reached = false;
    best_sinr_data = uma_sinr_data;
    umi_transmitters = [];
    attempts = 1;
    while ~best_sinr_data_reached && attempts < MAX_NUMBER_OF_ATTEMPTS
        disp (" - Coverage attempt number " + attempts);
        [umi_cell_latitudes, umi_cell_longitudes] = calculate_small_cells_coordinates_from_sinr(best_sinr_data, data_latitudes, data_longitudes);
        umi_transmitters = [umi_transmitters get_transmitters_from_coordinates(umi_cell_latitudes, umi_cell_longitudes, umi_blind_spot_model)];
        umi_blind_spot_model.frequency = umi_blind_spot_model.frequency + 100e6;
        [merged_latitudes, merged_longitudes, merged_grid_size, best_sinr_data] = calculate_sinr_values_map([umi_transmitters uma_transmitters], coordinates_bbox, PROPAGATION_MODEL);
        best_sinr_data_reached = ~ismember(1, best_sinr_data < 0);
        [umi_data_latitudes, umi_data_longitudes, best_umi_grid_size, umi_sinr_data] = calculate_sinr_values_map(umi_transmitters, coordinates_bbox, PROPAGATION_MODEL);
        attempts = attempts + 1;
    end
else
    disp("Computing UMi Layer in users demand mode");
    % UMI capacity - Social attractors
    disp("Generating UMi close to social attractors");

    [umi_cell_latitudes, umi_cell_longitudes] =  calculate_small_cells_from_social_attractors(social_attractors_latitudes, social_attractors_longitudes, social_attractors_weighting);
    [umi_cell_latitudes, umi_cell_longitudes] = deduplicate_transmitters_from_coordinates(umi_cell_latitudes, umi_cell_longitudes);

    umi_transmitters = get_transmitters_from_coordinates(umi_cell_latitudes, umi_cell_longitudes, umi_hotspot_model);

    % UMI capacity - hexagons
    disp("Generating UMi distributed layer");
    [distributed_latitudes, distributed_longitudes] = distribute_umi_cells_among_box(coordinates_bbox, UMI_ISD);
    umi_transmitters = [umi_transmitters get_transmitters_from_coordinates(distributed_latitudes, distributed_longitudes, umi_coverage_model)];
    [umi_data_latitudes, umi_data_longitudes, best_umi_grid_size, umi_sinr_data] = calculate_sinr_values_map(umi_transmitters, coordinates_bbox, PROPAGATION_MODEL);

    % UMI coverage - blind points
    disp("Generating UMi to cover blind points");
    [merged_latitudes, merged_longitudes, merged_grid_size, best_sinr_data] = calculate_sinr_values_map([uma_transmitters umi_transmitters], coordinates_bbox, PROPAGATION_MODEL);
    [new_umi_cell_latitudes, new_umi_cell_longitudes] = ...
        calculate_small_cells_coordinates_from_sinr(best_sinr_data, ...
        data_latitudes, data_longitudes);
    umi_transmitters = [umi_transmitters get_transmitters_from_coordinates(new_umi_cell_latitudes, new_umi_cell_longitudes, umi_blind_spot_model)];
    [umi_data_latitudes, umi_data_longitudes, best_umi_grid_size, umi_sinr_data] = calculate_sinr_values_map(umi_transmitters, coordinates_bbox, PROPAGATION_MODEL);
    [merged_latitudes, merged_longitudes, merged_grid_size, best_sinr_data] = calculate_sinr_values_map([uma_transmitters umi_transmitters], coordinates_bbox, PROPAGATION_MODEL);
end

%% Results
disp("Showing final map...");

%map = siteviewer('Buildings', 'map.osm');
plot_values_map([uma_transmitters umi_transmitters], merged_latitudes, merged_longitudes, merged_grid_size, best_sinr_data);
show(receivers, 'Icon', 'pins/receiver.png', 'IconSize', [18 18]);
show_legend(map);

%% UMI Backhaul
disp("Computing backhaul...");
all_the_transmitters = [umi_transmitters uma_transmitters];
backhaul_matrix = get_backhaul_relation(uma_transmitters, umi_transmitters);

for i = 1:length(backhaul_matrix)
    current_uma = backhaul_matrix(i);
    if current_uma ~= 0
        los(uma_transmitters(current_uma), umi_transmitters(i));
    end
end

%% Results
disp("Generating SINR matrix for all the receivers");
sinr_matrix = get_sinr_matrix_for_all_the_transmitters(receivers, all_the_transmitters);
%power_matrix = get_power_matrix_for_all_the_transmitters(receivers, all_the_transmitters);

count = 0;
for i = 1:length(sinr_matrix(1, :))
    contains = false;
    for j = 1:length(sinr_matrix(:, 1))
        if sinr_matrix(j, i) > 0
            contains = true;
        end
    end
    if contains
        count = count + 1;
    end
end
sinr_matrix(sinr_matrix < 0) = 0;
capacity_matrix = BW * log2(1 + sinr_matrix);

disp("Computing pairing...");
pairing_capacity = zeros(1, NUMBER_OF_RECEIVERS);
pairing_matrix = zeros(1, NUMBER_OF_RECEIVERS);
pairing_names = cellstr('');
total_capacity = zeros(1, length(all_the_transmitters));
for i = 1:NUMBER_OF_RECEIVERS
    [value, index] = max(capacity_matrix(:, i));
    
    pairing_matrix(i) = index;
    pairing_names(i) = cellstr(string(all_the_transmitters(index).Name));
    pairing_capacity(i) = value;
    total_capacity(index) = total_capacity(index) + value;
end

traffic_uma = zeros(1, length(uma_transmitters));
for i = 1:length(traffic_uma)
    linked_umi = find(backhaul_matrix == i);
    for j = 1:length(linked_umi)
        traffic_uma(i) = traffic_uma(i) + total_capacity(linked_umi(j));
    end
end

%% Results for uma
disp("Saving results...");
file_id = fopen('summary.txt','w');
for i = 1:3:length(uma_transmitters)-2
    transmitter_offset = length(umi_transmitters);
    name = "Name: " + uma_transmitters(i).Name;
    location = " - Location: " + uma_transmitters(i).Latitude + " , " + uma_transmitters(i).Longitude;
    power = " - Power: " + uma_transmitters(i).TransmitterPower + " W";
    frequency = " - Frequency: " + uma_transmitters(i).TransmitterFrequency/1e9 + " GHz";
    angles = " - Sector angles: " + uma_transmitters(i).AntennaAngle + " " + uma_transmitters(i+1).AntennaAngle + " " + uma_transmitters(i+2).AntennaAngle;
    connected_users = " - Connected users: " + length(find(pairing_matrix == i + transmitter_offset | pairing_matrix == i+1 + transmitter_offset | pairing_matrix == i+2 + transmitter_offset));
    users_traffic = " - Traffic demanded by users: " + sum(total_capacity(transmitter_offset+i : transmitter_offset+i+2)) + " Mbps";
    umi_traffic = " - Traffic demanded by UMis: " + sum(traffic_uma(i:i+2)) + " Mbps";
    fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n', name, location, power, frequency, angles, connected_users, users_traffic, umi_traffic);
end

%% Results for umi

for i = 1:length(umi_transmitters)
    name = "Name: " + umi_transmitters(i).Name;
    location = " - Location: " + umi_transmitters(i).Latitude + " , " + umi_transmitters(i).Longitude;
    power = " - Power: " + umi_transmitters(i).TransmitterPower + " W";
    frequency = " - Frequency: " + umi_transmitters(i).TransmitterFrequency/1e9 + " GHz";
    connected_users = " - Connected users: " + length(find(pairing_matrix == i));
    users_traffic = " - Traffic demanded by users: " + sum(total_capacity(i)) + " Mbps";
    connected_to = " - Backhaul to: " + uma_transmitters(backhaul_matrix(i)).Name;
    pointing_to = " - Backhaul to coordinates: " + uma_transmitters(backhaul_matrix(i)).Latitude + " , " + uma_transmitters(backhaul_matrix(i)).Longitude;
    fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n', name, location, power, frequency, connected_users, users_traffic, connected_to, pointing_to);
end

%% Summary
a = txsite("Latitude", lat_max, "Longitude", lon_max);
b = txsite("Latitude", lat_min, "Longitude", lon_max);
c = txsite("Latitude", lat_min, "Longitude", lon_min);
height = distance(a, b)/1000; % km
wide = distance(b, c)/1000; % km
area = height*wide; % km^2

coverage = length(find(best_sinr_data > 0))/length(best_sinr_data)*100;
uma_coverage = length(find(uma_sinr_data > 0))/length(uma_sinr_data)*100;
umi_coverage = length(find(umi_sinr_data > 0))/length(umi_sinr_data)*100;
users_coverage = NUMBER_OF_RECEIVERS - count;
traffic = sum(total_capacity)/NUMBER_OF_RECEIVERS;
traffic_area = sum(total_capacity)/area;

coverage_message = " - Total coverage (UMa + UMi): " + coverage + " % (area with SINR > 0 dB)"; 
uma_coverage_message = " - UMa layer coverage: " + uma_coverage + " %";
umi_coverage_message = " - UMi layer coverage: " + umi_coverage + " %";
users_coverage_message = " - Users whose SINR < 0 dB: " + users_coverage + " out of " + NUMBER_OF_RECEIVERS;
total_network_traffic = " - Total Network traffic: " + sum(total_capacity) + " Mbps";
mean_traffic = " - Mean traffic per user: " + traffic + " Mbps";
traffic_area_message = " - Traffic / area: " + traffic_area + " Mbps/Km^2";
total_uma = " - Total number of UMa: " + length(uma_transmitters);
total_umi = " - Total number of UMi: " + length(umi_transmitters);

fprintf(file_id, '\n------- SUMMARY ------- \n');
fprintf(file_id, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n', coverage_message, uma_coverage_message, umi_coverage_message, users_coverage_message, total_network_traffic, mean_traffic, traffic_area_message, total_uma, total_umi);
fclose(file_id);
disp("Finished! You can check the summary openning summary.txt");
end