clear all;
clearvars; clc; close all;
% add path BOOOM
addpath('./BOOOM/');
% add path supplement
addpath('./supplement/');
% add path AccAltProj
addpath('./supplement/AccAltProj/');
% add path GoDec plus
addpath('./supplement/GoDec_plus/');
% add path LRSD TNNSR
addpath('./supplement/LRSD-TNNSR/');


% add path simulation result
addpath('./Simulation result')
% addpath('./Simulation result/esimated')



% choose the dimensions of X (n×p), e.g., (50×10) or (70×20).
% n: the number of rows
% p: the number of columns
% d: target rank for low-rank matrix L


n = [50,70,100,100];
p = [10,20,50,100];
d = 5;

input_length = length(n);


% skip BOOOM
skip_BOOOM = 1;              % 1 = skip BOOOM, 0 = run it
% skip Booom Parallel
skip_BOOOM_parallel = 1;     % 1 = skip BOOOM_parallel, 0 = run it

% skip AccAlt Projections
skip_AccAlt_projection = 0;  % 1 = skip AccAlt Projections, 0 = run it

% skip GoDec+ Algorithm
skip_GoDec_plus =0;          % 1 = skip GoDec+, 0 = run it

% set GoDec+ parameters
epsilon = 1e-6;
q = 5;

% skip LRSD-TNNSR
skip_LRSD_TNNSR = 0;         % 1 = skip LRSD-TNNSR, 0 = run it

% simulation runs
experiment = 10;

% MAE, value and method computation time 

MAE_L_results = nan(experiment,5);

comp_time = nan(experiment,5);


for i = 1:input_length
    
    for ii = 1:experiment
        rand_seed = ii;
        rng(rand_seed);
        

        % BOOOM tuning parameters
        maxtime_each = 3600;
        TolFun1 = 10^(-9);
        
        % generate data X
        [X,L,S] = generate_data(n(i),p(i),d); 
        % generate orthonormal matrix dxr
        [Q_initial, ~] = qr(randn(p(i),d), 0);
        
        % set objective function
        lambda = 1/sqrt(max(n(i),p(i)));
        objFun = @(Q) objective_function(X, Q, lambda);

        [MAE_L_BOOOM,comp_time_BOOOM]=deal(nan);
        if skip_BOOOM == 0
            [Q_BOOOM, fval_BOOOM, comp_time_BOOOM] = BOOOM(objFun, Q_initial, maxtime_each, [], [], [], [], TolFun1);
            L_hat = (X*Q_BOOOM)*Q_BOOOM';
            S_hat = X-(X*Q_BOOOM)*Q_BOOOM';
                
            M = eval_metrics(X, L, S, L_hat, S_hat);


            MAE_L_BOOOM = M.L.MAE;

        end

        [MAE_L_BOOOM_Parallel,comp_time_BOOOM_P]=deal(nan);

        if skip_BOOOM_parallel ==0
            [Q_BOOOM_P, fval_BOOOM_P, comp_time_BOOOM_P] = BOOOMparallel(objFun, Q_initial, maxtime_each, [], [], [], [], TolFun1);
            L_hat = (X*Q_BOOOM_P)*Q_BOOOM_P';
            S_hat = X - (X*Q_BOOOM_P)*Q_BOOOM_P';

            M= eval_metrics(X, L, S, L_hat, S_hat);


            MAE_L_BOOOM_Parallel = M.L.MAE;

        end

        [MAE_L_AccAlt_projection,AccAlt_execution_time]=deal(nan);

        if skip_AccAlt_projection == 0
            tic;
            [L_hat, S_hat ] = AccAltProj_synthetic(X, d, '' ); % use default setting parameters (synthetic data setting)
            AccAlt_execution_time = toc;

            M = eval_metrics(X, L, S, L_hat, S_hat);


            MAE_L_AccAlt_projection = M.L.MAE;

        end




        [MAE_L_GoDec_plus,GoDec_plus_execution_time]=deal(nan);

        if skip_GoDec_plus == 0
            %%%%%% Our data generation yields many 0'. if the 2*median is
            %%%%%% 0, we set sigma very close to 0 eg eps.
            if 2*median(S.^2,"all") == 0   
                sigma = eps;
            else 
                sigma = 2*median(S.^2,"all");
            end
            tic;
            [L_hat,rel_err,base,Q,iter]=lowrank_corr(X,d,sigma,epsilon,q); % use default setting parameters 
            GoDec_plus_execution_time = toc;
            S_hat = X - L_hat;

            M = eval_metrics(X, L, S, L_hat, S_hat);

            MAE_L_GoDec_plus = M.L.MAE;

        end

       
        [MAE_L_LRSD_TNNSR,LRSD_TNNSR_execution_time]=deal(nan);
        if skip_LRSD_TNNSR == 0
            lower_R = d;
            upper_R = d;
            tic;
            % L_hat is not defined in the original function from the author
            % Adding L_hat as output does not change any calculation in the
            % function. 
            [ret, L_hat, S_hat]= admm_pic(L,S, X, lower_R, upper_R); % use default setting parameters %% Synthetic data setting
            LRSD_TNNSR_execution_time = toc;

            M = eval_metrics(X, L, S, L_hat, S_hat);

            MAE_L_LRSD_TNNSR = M.L.MAE;


        end

       
        MAE_L_results(ii,:) = [MAE_L_BOOOM,MAE_L_BOOOM_Parallel,MAE_L_AccAlt_projection,MAE_L_GoDec_plus,MAE_L_LRSD_TNNSR];

        comp_time(ii,:) = [comp_time_BOOOM,comp_time_BOOOM_P,AccAlt_execution_time,GoDec_plus_execution_time,LRSD_TNNSR_execution_time];


    end

    % timestamp = datestr(now, 'yyyymmdd_HHMM');

    % save evaluation metrics


    filename = fullfile('./Simulation result', ...
        ['All_funvals_MAE_L' '_n_' num2str(n(i)) '_p_' num2str(p(i)) '_d_' num2str(d) '_reps_' num2str(experiment)  '.csv']);
    writematrix(MAE_L_results, filename);



    % computation time
    filename = fullfile('./Simulation result', ...
        ['All_comp_times' '_n_' num2str(n(i)) '_p_' num2str(p(i)) '_d_' num2str(d) '_reps_' num2str(experiment)  '.csv']);
    writematrix(comp_time, filename);


end

