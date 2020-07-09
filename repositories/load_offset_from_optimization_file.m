function [offset] = load_offset_from_optimization_file(number_of_txs)
    files = dir('Prueba_generation_*.mat');

    if isempty(files)
        offset = generate_random_cell_angles(number_of_txs);
    else
        indexes = zeros(1, length(files));

        for i = 1:length(files)
            regexp_number_expression = '\d{1,}';
            file_index = regexp(files(i).name, regexp_number_expression, 'match');
            indexes(i) = str2double(file_index);
        end
        [value, ~] = max(indexes);

        load(['Prueba_generation_' num2str(value) '.mat'], 'state');

        scores = state.Score;
        best_score_position = find_best_score(scores);
        offset = state.Population(best_score_position, :).*120;
    end
end

function [position] = find_best_score(scores)
    best_score = 1e10;
    position = 1;
    for i = 1:length(scores)
        if scores(i, 1) < best_score
            position = i;
            best_score = scores(i);
        end
    end
end