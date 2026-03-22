clear all;
clearvars; clc; close all;
addpath('./Simulation result');



% Methods ={'BOOOM','BOOOM parallel','AccAlt projection','GoDec+','LRSD TNNSR'};
Methods ={'BOOOM','BOOOM parallel','AccAlt projection','GoDec+','LRSD TNNSR'};
metric_type = {'MAE'};

data_dim= [50, 10;
           70, 20;
           100, 50;
           100, 100];


rank_list = {5,10};

final_summary = table();

for i = 1:length(metric_type)
    for j = 1:size(data_dim, 1)
        n_val = data_dim(j, 1);
        p_val = data_dim(j, 2);
        for k = 1:length(rank_list)
            d_val = rank_list{k};

        
        fname_funvals = ['All_funvals_',metric_type{i},'_L','_n_',num2str(n_val), '_p_', num2str(p_val), '_d_',num2str(d_val),'_reps_10.csv'];
        fname_compvals = ['All_comp_times_n_', num2str(n_val), '_p_', num2str(p_val), '_d_', num2str(d_val), '_reps_10.csv'];


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
        

        Methods ={'BOOOM','BOOOM parallel','AccAlt_projection','GoDec+','LRSD TNNSR'}; 
        summary_table.Methods = Methods(:);
        summary_table = summary_table(:, [{'Methods'}, summary_table.Properties.VariableNames(1:end-1)]);

       
        summary_fname = fullfile('./Simulation result',['summary_', metric_type{i},'_L','_n_',num2str(n_val), '_p_', num2str(p_val), '_d_',num2str(d_val),'.csv']);
        writetable(summary_table, summary_fname);

        end
    end
end


