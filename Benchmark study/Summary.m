clearvars; clc; close all;
simulation_folder = 'Simulation result';
addpath('./Simulation result/');


funcNames = {'ackley', 'griewank', 'rosenbrock','rastrigin'};
M_values = [10, 20, 50, 100];
num_reps = 10;
methods = {'BOOOM', 'BOOOMparallel', 'fmincon:active-set', 'fmincon:interior-point',...
    'fmincon:sqp', 'Manopt:barzilai-borwein', 'Manopt:conjugate-gradient',...
    'Manopt:steepest-descent', 'Manopt:trust-region'};
colNames = {'min value', 'value s.e.', 'mean time', 'time s.e.'};

% Generate the filenames
for i = 1:length(funcNames)
    for j = 1:length(M_values)
        fname = sprintf('All_funvals_%s_M_%d_reps_10.csv', funcNames{i}, M_values(j));
        funvals = readmatrix(fname);
        fname2 = sprintf('All_comp_times_%s_M_%d_reps_10.csv', funcNames{i}, M_values(j));
        comp_times = readmatrix(fname2);
        
        
        min_funvals = min(funvals);
        stderr_funvals = std(funvals) / sqrt(num_reps);
        mean_times = mean(comp_times);
        stderr_times = std(comp_times) / sqrt(num_reps);
        
        % Combine into a 9 x 4 matrix
        summary_matrix = [min_funvals' stderr_funvals' mean_times' stderr_times'];
        
        formatted_min_funvals = arrayfun(@(x) sprintf('%.2e', x), summary_matrix(:, 1), 'UniformOutput', false);
        formatted_stderr_funvals = arrayfun(@(x) sprintf('%.2e', x), summary_matrix(:, 2), 'UniformOutput', false);
        mean_times = summary_matrix(:, 3);
        truncated_mean_times = fix(mean_times * 100) / 100;
        stderr_times = summary_matrix(:, 4);
        truncated_stderr_times = fix(stderr_times * 1000) / 1000;
        
        formatted_time = arrayfun(@(m, s) sprintf('%.2f (%.3f)', m, s), mean_times, stderr_times, 'UniformOutput', false);

        % Create table with three columns
        summary_table = table(formatted_min_funvals, formatted_stderr_funvals, formatted_time, ...
            'VariableNames', {'min value', 'value s.e.', 'time [mean (se)]'}, ...
            'RowNames', methods);

        output_fname = fullfile(simulation_folder,sprintf('Summary_%s_M_%d.csv', funcNames{i}, M_values(j)));
        writetable(summary_table, output_fname, 'WriteRowNames', true);
        
    end
end