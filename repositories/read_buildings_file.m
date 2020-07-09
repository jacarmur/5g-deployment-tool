function [social_attractors_latitudes, social_attractors_longitudes, ...
    social_attractors_weighting ] = read_buildings_file()
    dictionary = read_file();
    building_weighting = load_building_weighting();
    social_attractors_latitudes = zeros(1, length(dictionary));
    social_attractors_longitudes = zeros(1, length(dictionary));
    social_attractors_weighting = zeros(1, length(dictionary));
    for i = 1:length(dictionary)
        social_attractors_latitudes(i) = dictionary(i).latitude;
        social_attractors_longitudes(i) = dictionary(i).longitude;
        
        if isKey(building_weighting, dictionary(i).type)
            social_attractors_weighting(i) = building_weighting(dictionary(i).type);
        else
            social_attractors_weighting(i) = 1;
        end
    end
end

function [dictionary] = read_file()
    file_name = 'buildings_info.json'; 
    file_id = fopen(file_name); 
    raw_file = fread(file_id,inf); 
    string_file = char(raw_file'); 
    fclose(file_id); 
    dictionary = jsondecode(string_file);
end

function [building_types] = get_building_types()
    building_types = {'public', 'sports_hall', 'commercial', 'carport', ...
        'supermarket', 'hospital', 'yes', 'residential', 'service', ...
        'apartments', 'school', 'roof', 'university', 'church'};
end

function [] = save_building_weighting(building_weighting)
    save('building_weighting.mat', 'building_weighting');
end

function [building_weighting] = load_building_weighting()
    load('building_weighting.mat', 'building_weighting');
end