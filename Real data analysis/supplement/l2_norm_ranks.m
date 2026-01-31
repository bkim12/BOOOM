function [ranks, sorted_l2 ,non_zero_val] = l2_norm_ranks(cells)
    num_cells = size(cells,1);
    num_rows = size(cells{1,1},1);

    ranks = nan(num_rows, num_cells);
    sorted_l2 = zeros(num_rows, num_cells);
    non_zero_val = zeros(num_rows, num_cells);

    for i = 1:size(cells,1)
        l2_norms = sqrt(sum(cells{i}.^2, 2));
        [vals, idx] = sort(l2_norms, 'descend');

        ranks(:, i) = idx;
        sorted_l2(:, i) = vals;

        non_zero_sorted_val_idx = vals>0.01;
        non_zero_val(:, i) = non_zero_sorted_val_idx;
    end


end

