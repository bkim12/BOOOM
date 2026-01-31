clear all;
clearvars; clc; close all;

addpath('./Data/Yachida');
addpath('./Results');
addpath('./supplement');

% Ranking QN
% Pareto-optimal penalty pairs (lambda1, lambda2) selected from the Pareto curve
% optimal lambda combination (lambda1,lambda2) : (10^6,10^3), (10^5,10^1), (10^4,10^1), (10^4,10^0), (10^3,10^0)
optimal_lambda1 = [6];
optimal_lambda2 = [3];
var_ranks = cell(110, length(optimal_lambda1));
var_names = readcell("X_2_names_wo_mp_hs_110.csv");
var_l2_vals = zeros(110, length(optimal_lambda1));
non_zeros_indicator = zeros(110, length(optimal_lambda1));


for i = 1:length(optimal_lambda1)
    load(['Q_matrices_d_20_',num2str(optimal_lambda1(i)),'.mat']);
    [ranks, sorted_l2 ,non_zero_val]=l2_norm_ranks(Q_matrices_cell);

    struct.(['ranks_',num2str(optimal_lambda1(i))]) = ranks;
    ranks = struct.(['ranks_',num2str(optimal_lambda1(i))])(:,optimal_lambda2(i)+1);
    var_names_ranks = var_names(ranks);
    var_ranks(:,i) =var_names_ranks;

    struct.(['sorted_l2',num2str(optimal_lambda1(i))]) = sorted_l2;
    l2_vals = struct.(['sorted_l2',num2str(optimal_lambda1(i))])(:,optimal_lambda2(i)+1);
    var_l2_vals(:,i) =l2_vals;

    struct.(['non_zero_val',num2str(optimal_lambda1(i))]) = non_zero_val;
    non_zero_sorted_idx = struct.(['non_zero_val',num2str(optimal_lambda1(i))])(:,optimal_lambda2(i)+1);
    non_zeros_indicator(:,i) =non_zero_sorted_idx;
end

filename = fullfile('./Results','var_ranks_QN2.csv');
writecell(var_ranks, filename);

filename = fullfile('./Results','var_l2_vals_QN2.csv');
writematrix(var_l2_vals, filename);

filename = fullfile('./Results','non_zeros_indicator_QN2.csv');
writematrix(non_zeros_indicator, filename);

