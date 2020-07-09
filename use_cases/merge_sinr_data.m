function [final_sinr] = merge_sinr_data(sinr1, sinr2)
    final_sinr = zeros(1, length(sinr2));
    for i = 1:length(sinr2)
        final_sinr(i) = max(sinr1(i), sinr2(i));
    end
end

