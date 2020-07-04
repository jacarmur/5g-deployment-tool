function [idx,C,sumd,final_k]=best_kmeans(input_data)
dimensions = size(input_data);

maximum_iterations = 10;
distortion=zeros(dimensions(1),1);
if dimensions(1) > 100
    max_k = 100;
else
    max_k = dimensions(1);
end

for current_k = 1:max_k
    [~, ~, d] = kmeans(input_data, current_k, 'emptyaction', 'drop');
    current_distortion = sum(d);
    
    for test_count=2:maximum_iterations
        [~,~,d] = kmeans(input_data, current_k, 'emptyaction', 'drop');
        current_distortion = min(current_distortion, sum(d));
    end
    distortion(current_k, 1)=current_distortion;
end
variance = distortion(1:end - 1) - distortion(2:end);
distortion_percent = cumsum(variance) / (distortion(1) - distortion(end));
[r, ~] = find( distortion_percent > 0.9 );
final_k = r(1, 1) + 1;
[idx, C, sumd] = kmeans(input_data, final_k);
end
