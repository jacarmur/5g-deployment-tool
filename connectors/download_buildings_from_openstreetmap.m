function [] = download_buildings_from_openstreetmap(bbox_map)
    map_uri = 'https://api.openstreetmap.org/api/0.6/map';
    options = weboptions('ContentType', 'xml', 'Timeout', 10);
    map_file = websave('map.osm', map_uri, 'bbox', bbox_map, options);
end

