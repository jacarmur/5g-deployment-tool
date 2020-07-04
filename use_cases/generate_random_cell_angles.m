function [offsets] = generate_random_cell_angles(number_of_transmitters)
offsets = zeros(1, number_of_transmitters*3);
for i=1:length(offsets)
    offsets(i) = randi(120)-1;
end
end

