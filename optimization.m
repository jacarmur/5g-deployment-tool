clear all
close all

% Configuration

load('matlab.mat');
for i=1:200
cell_angles = generate_random_cell_angles(length(uma_latitudes));
transmitters = get_transmitters_from_coordinates(uma_latitudes, uma_longitudes, UMA_TX_POWER, UMA_FREQUENCY, cell_angles);

[data_latitudes, data_longitudes, grid_size, sinr_data] = calculate_sinr_values_map(transmitters, coordinates_bbox);
sinr_points = length(find(sinr_data<0));
    if sinr_points < uma_sinr_score
        uma_data_latitudes = data_latitudes;
        uma_data_longitudes = data_longitudes;
        uma_grid_size = grid_size;
        uma_sinr_data = sinr_data; 
        uma_sinr_score = sinr_points;
        uma_offset = cell_angles;
        uma_transmitters = transmitters;
    end
    i
end
plot_values_map(uma_transmitters, uma_data_latitudes, uma_data_longitudes, uma_grid_size, uma_sinr_data);
