function [small_cell_latitudes, small_cell_longitudes] = calculate_small_cells_coordinates_from_sinr(sinr_data, latitudes, longitudes, varargin)

points_with_low_sinr = sinr_data < 0;
X1 = latitudes(points_with_low_sinr);
X2 = longitudes(points_with_low_sinr);
[X1G, X2G] = meshgrid(X1, X2);
XGrid = [X1G(:), X2G(:)];
[~, C, ~, ~] = best_kmeans(XGrid);
small_cell_latitudes = C(:, 1);
small_cell_longitudes = C(:, 2);

end

