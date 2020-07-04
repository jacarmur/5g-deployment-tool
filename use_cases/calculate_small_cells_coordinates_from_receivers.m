function [small_cell_latitudes, small_cell_longitudes] = calculate_small_cells_coordinates_from_receivers(receivers)

latitudes = zeros(1, length(receivers));
longitudes = zeros(1, length(receivers));

for i = 1:length(receivers)
    latitudes(i) = receivers(i).Latitude;
    longitudes(i) = receivers(i).Longitude;
end

X1 = latitudes;
X2 = longitudes;
[X1G, X2G] = meshgrid(X1, X2);
XGrid = [X1G(:), X2G(:)];
[~, C, ~, ~] = best_kmeans(XGrid);
small_cell_latitudes = C(:, 1);
small_cell_longitudes = C(:, 2);

end
