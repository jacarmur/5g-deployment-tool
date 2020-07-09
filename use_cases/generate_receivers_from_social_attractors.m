function [receivers_latitudes, receivers_longitudes] = generate_receivers_from_social_attractors(...
    social_attractors_latitudes, social_attractors_longitudes, ...
    social_attractors_weighting, number_of_receivers, bbox_map)
receivers_latitudes = zeros(1, number_of_receivers);
receivers_longitudes = zeros(1, number_of_receivers);

weighting_sum = sum(social_attractors_weighting);
assigned_users = zeros(1, length(social_attractors_weighting));
for i = 1:length(social_attractors_weighting)
    if i == 1
        base = 1;
    else
        base = sum(assigned_users)+1;
    end
    assigned_users(i) = round((social_attractors_weighting(i) / ...
        weighting_sum) * number_of_receivers);

    [receivers_latitudes(base:base+assigned_users(i)-1), ...
        receivers_longitudes(base:base+assigned_users(i)-1)] = ...
        generate_users_around_social_attractor(...
        social_attractors_latitudes(i), social_attractors_longitudes(i),...
        assigned_users(i), bbox_map);
end

for i = sum(assigned_users):number_of_receivers
    building_index = randi(length(social_attractors_weighting));
    [receivers_latitudes(i), receivers_longitudes(i)] = generate_users_around_social_attractor(...
        social_attractors_latitudes(building_index), social_attractors_longitudes(building_index), 1, bbox_map);
end
end

function [receivers_latitudes, receivers_longitudes] = generate_users_around_social_attractor(...
        social_attractor_latitude, social_attractor_longitude, assigned_users, bbox_map)
    receivers_latitudes = zeros(1, assigned_users);
    receivers_longitudes = zeros(1, assigned_users);
    
    for i = 1:assigned_users
        receivers_latitudes(i) = social_attractor_latitude + 0.001*(rand()-0.5);
        receivers_longitudes(i) = social_attractor_longitude+ 0.001*(rand()-0.5);
        
        if receivers_latitudes(i) < bbox_map.minimum_latitude || receivers_latitudes(i) > bbox_map.maximum_latitude
            receivers_latitudes(i) = social_attractor_latitude;
        end
        
        if receivers_longitudes(i) < bbox_map.minimum_longitude || receivers_longitudes(i) > bbox_map.maximum_longitude
            receivers_longitudes(i) = social_attractor_longitude;
        end
    end
end