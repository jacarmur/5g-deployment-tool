function [latitudes, longitudes] = distribute_umi_cells_among_box(bbox, isd)

RAD3_OVER2 = sqrt(3) / 2;

center_latitude = (bbox.maximum_latitude + bbox.minimum_latitude)/2;
center_longitude = (bbox.maximum_longitude + bbox.minimum_longitude)/2;

outter_site = txsite('Name','Outer', ...
    'Latitude', bbox.maximum_latitude,...
    'Longitude', bbox.maximum_longitude);
center_site = txsite('Name','Center', ...
    'Latitude', center_latitude,...
    'Longitude', center_longitude);
MAX_DISTANCE = distance(outter_site, center_site);

[X, Y] = meshgrid(0:1:41);
n = size(X,1);
X = RAD3_OVER2 * X;
Y = Y + repmat([0 0.5],[n,n/2]);
X = X * isd;
Y = Y * isd;

distance_with_center = zeros(1, n*n);
center_x = X(round(n/2), round(n/2));
center_y = Y(round(n/2), round(n/2));
for i = 1:length(X(:))
    distance_with_center(i) = sqrt((X(i)-center_x)^2 + (Y(i)-center_y)^2);
end
indexes = distance_with_center < MAX_DISTANCE;
distance_with_center = distance_with_center(indexes);
X = X(indexes);
Y = Y(indexes);

site_angles = zeros(1, length(X(:)));
for i = 1:length(X(:))
    site_angles(i) = rad2deg(atan2(Y(i) - center_y, X(i) - center_x));
end

latitudes = zeros(1, length(X(:)));
longitudes = zeros(1, length(X(:)));

for i = 1:length(X(:))
    [latitudes(i), longitudes(i)] = location(center_site, distance_with_center(i), site_angles(i));
end

coordinates_indexes = latitudes > bbox.minimum_latitude & longitudes > bbox.minimum_longitude...
    & latitudes < bbox.maximum_latitude & longitudes < bbox.maximum_longitude;
latitudes = latitudes(coordinates_indexes);
longitudes = longitudes(coordinates_indexes);
end

