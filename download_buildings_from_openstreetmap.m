function [] = download_buildings_from_openstreetmap(bbox_map)
map_uri = 'https://api.openstreetmap.org/api/0.6/map';
% todo: bbox a trozos
map_file = websave('downloaded_map2.osm', map_uri, 'bbox', bbox_map);
end
