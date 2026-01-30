clear all;
clearvars; clc; close all;
% add path BOOOM
addpath('./BOOOM/');
% add path supplement
addpath('./supplement/');
% add path simulation result
simulation_folder = 'Simulation result';
addpath(fullfile('.', simulation_folder));

% choose the dimensions of Q (p×d), e.g., (20×10) or (50×40).
% the matrices M_i are then generated with matching dimension p×p.
p = 20;
d = 10;

% skip BOOOM
BOOOM_skip = 0;           % 1 = skip BOOOM, 0 = run it
% skip Booom Parallel
BOOOM_parallel_skip = 0;  % 1 = skip BOOOM parallel, 0 = run it
% skip SDP
SDP_skip = 0;             % 1 = skip SDP, 0 = run it



% types of PSD (Positive Semidefinite) 
PSD_type = {'random', 'toeplitz', 'block diagonal'};   % index 1, 2, 3 
input_types = [1];  % [1]: random, [2]: toeplitz, [3]: block diagonal

% for block diagonal PSD; need a size of block.
num_blocks = 5; 

% simulation runs
num_experiment = 10;

% for BOOOM, SDP objective function values and computation time table
fval_results = nan(num_experiment,3);
comp_time_results = nan(num_experiment,3);

for i = 1:length(input_types)
    which_PSD = PSD_type{input_types(i)};

    if strcmp(which_PSD,'random')
        PSD = @(p) create_PSD(p);
    elseif strcmp(which_PSD,'toeplitz')
        PSD = @(p) create_toeplitz_PSD(p);
    elseif strcmp(which_PSD,'block diagonal')
        PSD = @(p, size) create_block_diagonal_PSD(p, size);
    end

    for ii = 1:num_experiment
        rand_seed = ii;
        rng(rand_seed);
        
        % now call the appropriate PSD function with arguments and
        % create d many M into a cell
        if strcmp(which_PSD, 'block diagonal')
            M_i = arrayfun(@(x) PSD(p, num_blocks), (1:d)', 'UniformOutput', false);
        else
            M_i = arrayfun(@(x) PSD(p), (1:d)', 'UniformOutput', false);
        end
        % disp(M_i)
        

        % BOOOM
        maxtime_each = 3600;
        TolFun1 = 10^(-9);
        [Q_initial, ~] = qr(randn(p,d), 0);

        objFun_min = @(Q) objective_function(M_i, Q, 'min');
        if BOOOM_skip == 0
            [Q_BOOOM, fval_BOOOM, comp_time_BOOOM] = BOOOM(objFun_min, Q_initial, maxtime_each, [], [], [], [], TolFun1);
            
            if BOOOM_parallel_skip ==0
                [Q_BOOOM_P, fval_BOOOM_P, comp_time_BOOOM_P] = BOOOMparallel(objFun_min, Q_initial, maxtime_each, [], [], [], [], TolFun1);
            end

            fval_BOOOM_max = -fval_BOOOM; 
            fval_BOOOM_P_max = -fval_BOOOM_P; 

        else 
            fval_BOOOM_max =NaN;
            fval_BOOOM_P_max =NaN;
  
            comp_time_BOOOM = NaN;
            comp_time_BOOOM_P = NaN;
        end



        %  SDP relaxation

        if SDP_skip ==0
            % calcuate computation timefor SDP
            tic;
            % The notation U used in the SDP relaxation is equivalent to Q
            % in the BOOOM objective formulation.
            [proj_err,Xi_err,cvx_optval,U_hat,X,nu,Z,Y] = solve_sdp_CVX(M_i);
            cvx_execution_time = toc;


            % find a maximum on the original objective function (non convex relaxed function)
            objFun_max = @(U) objective_function(M_i, U, 'max');
            fval_sdp = objFun_max(U_hat);

            disp("-----------------")
            cvx_execution_time;

        else
            fval_sdp =NaN;
            cvx_execution_time = NaN;
        end


        fval_results(ii,:) = [fval_BOOOM_max,fval_BOOOM_P_max,fval_sdp];
        comp_time_results(ii,:) = [comp_time_BOOOM,comp_time_BOOOM_P,cvx_execution_time];
    end


    % timestamp = datestr(now, 'yyyymmdd_HHMM');

    filename = fullfile(simulation_folder, ...
        ['All_funvals_' which_PSD  '_p_' num2str(p) '_d_' num2str(d) '_reps_' num2str(num_experiment)  '.csv']);
    writematrix(fval_results, filename);

    filename = fullfile(simulation_folder, ...
        ['All_comp_times_' which_PSD  '_p_' num2str(p) '_d_' num2str(d) '_reps_' num2str(num_experiment) '.csv']);
    writematrix(comp_time_results,filename);


end