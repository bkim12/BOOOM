clear all;
clearvars; clc; close all;

addpath('./BOOOM/');
addpath('./supplement/');
simulation_folder = 'Simulation result';
addpath(fullfile('.', simulation_folder));

% %%% Adding 'Manopt' to the path %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(pwd());
% Recursively add Manopt directories to the Matlab path.
cd('manopt');
addpath(genpath(pwd()));
cd('..');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%BOOOM
skip_BOOOM = 0;             % 1 = skip BOOOM, 0 = run it
skip_BOOOMparallel = 0;     % 1 = skip BOOOM parallel, 0 = run it
%fmincon
skip_activeset = 0;         % 1 = skip activeset, 0 = run it
skip_interiorpoint = 0;     % 1 = skip interiorpoint, 0 = run it
skip_sqp = 0;               % 1 = skip sqp, 0 = run it
% manopt
skip_barzilaiborwein = 0;   % 1 = skip barzilaiborwein, 0 = run it
skip_conjugategradient = 0; % 1 = skip conjugategradient, 0 = run it
skip_steepestdescent = 0;   % 1 = skip steepestdescent, 0 = run it
skip_trustregion = 0;       % 1 = skip trustregion, 0 = run it

fun_choices = {'ackley', 'griewank', 'rosenbrock','rastrigin'};  % index 1, 2, 3 ,4
input_vals = [1];  % [1]: ackley function, [2]: griewank function, [3]: rosenbrock function, [4]: rastrigin function 
M = 10;         % dimension of M = 10, 20, 50, 100 
Num_exp = 10;  % Number of experiments
maxtime_each = 3600; % For M = 50, 100, change maxtime to 3600*5
All_comp_times = nan(Num_exp, 9);
All_funvals = nan(Num_exp, 9);

for i = 1:length(input_vals)
    which_fun = fun_choices{input_vals(i)};
    
    if strcmp(which_fun, 'ackley')
        objFun = @(O) modified_ackley(O);
    elseif strcmp(which_fun, 'griewank')
        objFun = @(O) modified_griewank(O);
    elseif strcmp(which_fun, 'rosenbrock')
        objFun = @(O) modified_rosenbrock(O);
    elseif strcmp(which_fun, 'rastrigin')
        objFun = @(O) modified_rastrigin(O);    
    else
        error('Unknown function specified in which_fun.');
    end
    
    
    for ii = 1:Num_exp
        fprintf('Performing experiment number: %d using function: %s\n', ii, which_fun);
        rand_seed = ii;
        rng(rand_seed);
        % O_initial = orth(randn(M, M));
        [O_initial, ~] = qr(randn(M, M), 0);

        %%% BOOOM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [O_BOOOM, fval_BOOOM, comp_time_BOOOM] = deal(nan);
        if (skip_BOOOM == 0)
            [O_BOOOM, fval_BOOOM, comp_time_BOOOM] = BOOOM(objFun, O_initial, maxtime_each);
        end

        %%% BOOOM: parallel
        [O_BOOOMparallel, fval_BOOOMparallel, comp_time_BOOOMparallel] = deal(nan);
        if(skip_BOOOMparallel == 0)
            if(isempty(gcp('nocreate')))
                parpool;
            end
            [O_BOOOMparallel, fval_BOOOMparallel, comp_time_BOOOMparallel] = BOOOMparallel(objFun, O_initial, maxtime_each);
        end

        %% fmincon %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        x0 = reshape(O_initial,[],1); % Initial values for ortogonal matrix

        obj = @(x) objFun(reshape(x,M, M));
        ortogonalCon = @(x) orthogonalityConstraint(x, M, M);

        %% fmincon: active-set
        [x_opt_activeset, fval_activeset, comp_time_activeset] = deal(nan);
        if (skip_activeset == 0)
            options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'active-set','ConstraintTolerance', 1e-8, 'MaxFunctionEvaluations', 1e4);
            tic;
            [x_opt_activeset, fval_activeset] = fmincon(obj, x0, [], [], [], [], [], [], ortogonalCon, options);
            comp_time_activeset = toc;
        end

        %% fmincon: interior-point
        [x_opt_interiorpoint, fval_interiorpoint, comp_time_interiorpoint] = deal(nan);
        if (skip_interiorpoint == 0)
            options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'interior-point','ConstraintTolerance', 1e-8);
            tic;
            [x_opt_interiorpoint, fval_interiorpoint] = fmincon(obj, x0, [], [], [], [], [], [], ortogonalCon, options);
            comp_time_interiorpoint = toc;
        end

        %% fmincon: sqp
        [x_opt_sqp, fval_sqp, comp_time_sqp] = deal(nan);
        if (skip_sqp == 0)
            options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp', 'ConstraintTolerance', 1e-8);
            tic;
            [x_opt_sqp, fval_sqp] = fmincon(obj, x0, [], [], [], [], [], [], ortogonalCon, options);
            comp_time_sqp = toc;
        end



        
        %%% Manopt %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        rng(rand_seed)
        manifold = stiefelfactory(M, M);  % full-rank square matrix with orthogonal columns
        
        % Define your cost function
        problem.M = manifold;
        problem.cost = @(X) objFun(X);

        
        %%% Manopt: barzilai-borwein
        [Xopt_barzilaiborwein, xcost_barzilaiborwein, comp_time_barzilaiborwein] = deal(nan);
        if (skip_barzilaiborwein==0)
            tic;
            options = struct();
            options.maxtime = maxtime_each;
            [Xopt_barzilaiborwein, xcost_barzilaiborwein, info_barzilaiborwein] = barzilaiborwein(problem, O_initial, options);
            comp_time_barzilaiborwein = toc;
        end

        
        %%% Manopt: conjugate-gradient
        [Xopt_conjugategradient, xcost_conjugategradient, comp_time_conjugategradient] = deal(nan);
        if (skip_conjugategradient==0)
            tic;
            options = struct();
            options.maxtime = maxtime_each;
            [Xopt_conjugategradient, xcost_conjugategradient, info_conjugategradient] = conjugategradient(problem, O_initial, options);
            comp_time_conjugategradient = toc;
        end

        %%% Manopt: steepest-descent
        [Xopt_steepestdescent, xcost_steepestdescent, comp_time_steepestdescent] = deal(nan);
        if (skip_steepestdescent==0)
            tic;
            options = struct();
            options.maxtime = maxtime_each;
            [Xopt_steepestdescent, xcost_steepestdescent, info_steepestdescent] = steepestdescent(problem, O_initial, options);
            comp_time_steepestdescent = toc;
        end
        
        %%% Manopt: trust-region
        [Xopt_trustregion, xcost_trustregion, comp_time_trustregion] = deal(nan);
        if (skip_trustregion==0)
            tic;
            options = struct();
            options.maxtime = maxtime_each;
            [Xopt_trustregion, xcost_trustregion, info_trustregion] = trustregions(problem, O_initial, options);
            comp_time_trustregion = toc;
        end
        %%% Summary %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        All_comp_times(ii,:) = [comp_time_BOOOM, comp_time_BOOOMparallel,...
            comp_time_activeset, comp_time_interiorpoint, comp_time_sqp, comp_time_barzilaiborwein,...
            comp_time_conjugategradient, comp_time_steepestdescent, comp_time_trustregion];
        
        All_funvals(ii,:) = [fval_BOOOM, fval_BOOOMparallel,...
            fval_activeset, fval_interiorpoint,fval_sqp, xcost_barzilaiborwein,...
            xcost_conjugategradient, xcost_steepestdescent, xcost_trustregion];
        
    end
    

    % timestamp = datestr(now, 'yyyymmdd_HHMM');
    filename = fullfile(simulation_folder,['All_comp_times_' which_fun '_M_' num2str(M) '_reps_' num2str(Num_exp) '.csv']);
    writematrix(All_comp_times, filename);

    filename = fullfile(simulation_folder,['All_funvals_' which_fun '_M_' num2str(M) '_reps_' num2str(Num_exp) '.csv']);
    writematrix(All_funvals, filename);
    
end

