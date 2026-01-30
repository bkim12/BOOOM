clear all;
clearvars; clc; close all;
addpath('./Simulation result');



Methods ={'BOOOM','BOOOM parallel','SDP'}; % Simulation method
mat_type = {'random','block diagonal','toeplitz'}; % PSD (positive semidefinite) type 

% diemsion for Q (pxd) (20x10, 50x40)
pd_pairs = [20, 10;
            50, 40];

final_summary = table();

for i = 1:length(mat_type)
    for j = 1:size(pd_pairs, 1)
        p_val = pd_pairs(j, 1);
        d_val = pd_pairs(j, 2);

    
        fname_funvals = ['All_funvals_', mat_type{i}, '_p_', num2str(p_val), '_d_', num2str(d_val), '_reps_10', '.csv'];
        fname_compvals = ['All_comp_times_', mat_type{i}, '_p_', num2str(p_val), '_d_', num2str(d_val), '_reps_10','.csv'];


        funvals = readmatrix(fname_funvals);     
        compvals = readmatrix(fname_compvals);   


        median_funvals = median(funvals, 1);
        iqr_funvals = iqr(funvals, 1);
        median_compvals = median(compvals, 1);
        iqr_compvals = iqr(compvals, 1);


        formatted_median_funvals = arrayfun(@(x) sprintf('%.4f', x), median_funvals, 'UniformOutput', false);
        formatted_iqr_funvals = arrayfun(@(x) sprintf('%.4f', x), iqr_funvals, 'UniformOutput', false);
        
        formatted_time = arrayfun(@(med, iqr) sprintf('%.2f (%.2f)', med, iqr), ...
            median_compvals, iqr_compvals, 'UniformOutput', false);

      


        summary_table = table(formatted_median_funvals(:), ...
                              formatted_iqr_funvals(:), ...
                              formatted_time(:), ...
                              'VariableNames', {'median value', 'IQR of values', 'median time (IQR)'});
        

        Methods = {'BOOOM', 'BOOOM parallel', 'SDP'};  
        summary_table.Methods = Methods(:);
        summary_table = summary_table(:, [{'Methods'}, summary_table.Properties.VariableNames(1:end-1)]);

       
        summary_fname = fullfile('./Simulation result',['summary_', mat_type{i}, '_p_', num2str(p_val), '_d_', num2str(d_val), '.csv']);
        writetable(summary_table, summary_fname);

    end
end


