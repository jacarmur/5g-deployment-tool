function backhaul_indexes = get_backhaul_relation(uma_transmitters, umi_transmitters)
backhaul_indexes = zeros(1, length(umi_transmitters));

for i = 1:length(umi_transmitters)
    best_distance = 1e10;
    best_index = 0;
    for j = 1:length(uma_transmitters)/3
        if los(umi_transmitters(i), uma_transmitters(j*3))
            current_distance = get_distance(uma_transmitters(j*3), umi_transmitters(i));
            if current_distance < best_distance
                best_distance = current_distance;
                best_index = j*3;
            end
        end
    end
    if best_index == 0
        for j = 1:length(uma_transmitters)/3
            current_distance = get_distance(uma_transmitters(j*3), umi_transmitters(i));
            if current_distance < best_distance
                best_distance = current_distance;
                best_index = j*3;
            end
        end
    end
    backhaul_indexes(i) = best_index;
end

end

function final_distance = get_distance(transmitter1, transmitter2)
    lat1 = transmitter1.Latitude;
    lon1 = transmitter1.Longitude;
    lat2 = transmitter2.Latitude;
    lon2 = transmitter2.Longitude;
    
    final_distance = sqrt((lat1 - lat2)^2+(lon1 - lon2)^2);
end