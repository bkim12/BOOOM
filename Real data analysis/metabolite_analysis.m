clear all;
clearvars; clc; close all;
% add path BOOOM
addpath('./BOOOM/');
addpath('./supplement');
addpath('./Data/Yachida');
addpath('./Results');

%%%%%%
% Metabolite data dim (277x 110) quantile normalized scaled
X = readmatrix('X_2_wo_mp_hs_110_QN_scaled.csv');
% Patient cancer status (0: healthy, 1: cancer) 277
Y = readmatrix('Y_wo_mp_hs.csv');
%%%%%%



% regulization tuning parameter
% penalty1: penalty for l2,1 norm
% penalty2: penalty for Fisher discriminant loss
% lambda_comb: combination of penalty1 (lambda1) and penalty2 (lambda2)
% For computation efficiency, constrain penalty1 to a single value in each run to
% reduce the hyperparameter search space
% Penalty1 is an integer that can take values from 0 to 8.

penalty1 = [0];
penalty2 = linspace(0,8,9);
penalty2 = linspace(0,1,2);
[lambda1, lambda2] = meshgrid(10.^(penalty1), 10.^(penalty2));
lambda_comb = [lambda1(:), lambda2(:)]; % 1st column: lambda1, % 2nd column: lambda2 
lambda_comb_length = size(lambda_comb,1);



%%% BOOOM parameters 
MaxTime = 3600;
MaxRuns = 10;
MaxIter = 5000;
TolFun1 = 10^(-4);
TolFun2 = 10^(-2);

% skip BOOOM parallel 
BOOOM_parallel = 0;  % 1 = skip BOOOM parallel, 0 = run it


% initial orthonomal matrix (pxd)
p = size(X,2);
% the number of columns for orthonomal matrix;
d = [20];
input_d = length(d);

% number of subjects
n_subject = size(Y,1);

Q_matrices = cell(lambda_comb_length,1,input_d);
result_d = nan(lambda_comb_length, 3, input_d);
comp_time = nan(lambda_comb_length,1,input_d);
fvals = nan(lambda_comb_length, 1,input_d);

for i = 1:input_d

    % set an initial Q matrix
    rng(1234);
    [Q_initial, ~] = qr(randn(p, d(i)), 0);

    for ii = 1:lambda_comb_length
        lambdas = lambda_comb(ii,:);
        objFun = @(Q) objective_function(X,Q,Y,lambdas);
        
        % BOOOM
        if BOOOM_parallel == 0
            [Q_BOOOM, fval_BOOOM, comp_time_BOOOM] = BOOOMparallel(objFun, Q_initial, MaxTime, MaxRuns, MaxIter, ...
                [], [], TolFun1, TolFun2);

        else 
            [Q_BOOOM, fval_BOOOM, comp_time_BOOOM] = BOOOM(objFun, Q_initial, MaxTime, MaxRuns, MaxIter, ...
                [], [], TolFun1, TolFun2);
        end
        
        % save optimal BOOOM 
        Q_matrices{ii,:,i} = Q_BOOOM;

        % calculate misclassification rate
        [MR] = misclassification(X,Q_BOOOM,Y);

        % calculate 
        % metric1: ratio of number of non zero rows to total number of rows
        % metric2: ratio of zero elements to total number of elements out of non zero rows
        [metric1, metric2] = sparsity_metric(Q_BOOOM);

        result_d(ii,:,i) = [MR, metric1, metric2];
        comp_time(ii,i) = comp_time_BOOOM;
        fvals(ii,i) = fval_BOOOM;

    end

    final_result = [lambda_comb, result_d(:,:,i), comp_time(:,:,i), fvals(:,:,i)];

    % timestamp = datestr(now, 'yyyymmdd_HHMM');
    % lambda combinations, missclassification rate, metric1, metric2, computation time, fvals
    filename = fullfile('./Results',['Result_n_',num2str(n_subject),'_p_',num2str(p),'_d_', num2str(d(i)),'_',num2str(penalty1),'.csv']);
    writematrix(final_result, filename);
    
    % save Q_matrices for different lambda 1,2 combinations
    Q_matrices_cell = Q_matrices(:,:,i);
    filename = fullfile('./Results',['Q_matrices_d_', num2str(d(i)) ,'_',num2str(penalty1),'.mat']);
    save(filename,'Q_matrices_cell')

end


