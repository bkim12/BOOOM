%% ============================================================
%  AJD / Orthogonal Joint Diagonalization Simulation Study
%  Baselines:
%     1) Jacobi AJD
%     2) Riemannian Gradient (Manopt)
%     3) Riemannian Trust-Region (Manopt)
%     4) BOOOM
%  MATLAB 2021a compatible
%% ============================================================

clear; clc; close all;

addpath('./BOOOM/');
addpath(genpath('./supplement/'));
addpath(genpath('./supplement/manopt/'));

%% ------------------ BOOOM settings ------------------
BOOOM_parallel = 0;
runBOOOM = true;
maxtime_each = 3600;
TolFun1 = 1e-8;
MaxRuns = 5;

%% ------------------ SETTINGS ------------------
rng(1,'twister');

p = 20;    % 20/50 dimension of orthogonal matrix 
m = 10;    % 5/10 number of matrices
R = 10;    % Monte Carlo replicates
sigma_noise = 0.1;

%% ------------------ STORAGE ------------------
loss_jacobi = zeros(R,1);
loss_rg     = zeros(R,1);
loss_rtr    = zeros(R,1);
loss_booom  = zeros(R,1);

time_jacobi = zeros(R,1);
time_rg     = zeros(R,1);
time_rtr    = zeros(R,1);
time_booom  = zeros(R,1);

%% ============================================================
%                 MONTE CARLO LOOP
%% ============================================================
for r = 1:R
    fprintf('\n=== Replicate %d / %d ===\n', r, R);

    %% 1) True orthogonal diagonalizer
    [Q,~] = qr(randn(p,p),0);
    Wtrue = Q;

    %% 2) Generate matrices
    C = zeros(p,p,m);

    for k = 1:m
        dk = linspace(0.5,2.0,p)' + 0.2*randn(p,1);
        Dk = diag(dk);

        Ck = Wtrue * Dk * Wtrue';

        Ek = randn(p,p);
        Ek = (Ek + Ek')/2;

        C(:,:,k) = Ck + sigma_noise * Ek;
    end

    %% 3) Objective function
    objFun = @(W) ajd_offdiag_objective(C, W);

    %% =========================================================
    %% 1️⃣ Jacobi AJD
    %% =========================================================
    tic
    [W_jacobi,~] = ajd_jacobi(C,200,1e-12);
    time_jacobi(r) = toc;

    loss_jacobi(r) = objFun(W_jacobi);

    fprintf('JacobiAJD loss = %.6f | time = %.3f sec\n', ...
        loss_jacobi(r), time_jacobi(r));

    %% =========================================================
    %% 2️⃣ Riemannian Gradient (Manopt)
    %% =========================================================
    manifold = stiefelfactory(p,p);
    problem.M = manifold;

    problem.cost  = @(W) ajd_offdiag_objective(C,W);
    problem.egrad = @(W) ajd_egrad(C,W);

    options.maxiter = 200;
    options.tolgradnorm = 1e-8;
    options.verbosity = 0;

    W0 = manifold.rand();

    tic
    [W_rg,~] = steepestdescent(problem,W0,options);
    time_rg(r) = toc;

    loss_rg(r) = objFun(W_rg);

    fprintf('RiemGD    loss = %.6f | time = %.3f sec\n', ...
        loss_rg(r), time_rg(r));

    %% =========================================================
    %% 3️⃣ Riemannian Trust Region
    %% =========================================================
    options_rtr.maxiter = 200;
    options_rtr.tolgradnorm = 1e-8;
    options_rtr.verbosity = 0;

    W0 = manifold.rand();

    tic
    [W_rtr,~] = trustregions(problem,W0,options_rtr);
    time_rtr(r) = toc;

    loss_rtr(r) = objFun(W_rtr);

    fprintf('RTR       loss = %.6f | time = %.3f sec\n', ...
        loss_rtr(r), time_rtr(r));

    %% =========================================================
    %% 4️⃣ BOOOM
    %% =========================================================
    if runBOOOM

        [Q_initial,~] = qr(randn(p,p),0);
        objFun_min = @(Q) objFun(Q);

        if BOOOM_parallel == 1

            [W_BOOOM,fval_BOOOM,comp_time_BOOOM] = ...
                BOOOMparallel(objFun_min,Q_initial,maxtime_each,...
                MaxRuns,[],[],[],TolFun1);

        else

            [W_BOOOM,fval_BOOOM,comp_time_BOOOM] = ...
                BOOOM(objFun_min,Q_initial,maxtime_each,...
                MaxRuns,[],[],[],TolFun1);

        end

        time_booom(r) = comp_time_BOOOM;
        loss_booom(r) = fval_BOOOM;

        fprintf('BOOOM     loss = %.6f | time = %.3f sec\n', ...
            loss_booom(r), time_booom(r));

    end

end

%% ============================================================
%                      SUMMARY
%% ============================================================

fprintf('\n================ SUMMARY ================\n')

methods = {'JacobiAJD','RiemGD','RTR','BOOOM'};

ObjMat = [loss_jacobi, loss_rg, loss_rtr, loss_booom];
TiMat  = [time_jacobi, time_rg, time_rtr, time_booom];

for i = 1:length(methods)

    fprintf('%s mean loss = %.6f (SE = %.6f)\n', ...
        methods{i}, mean(ObjMat(:,i)), std(ObjMat(:,i))/sqrt(R));

end

%% ============================================================
%                    SAVE RESULTS TO FILES
%% ============================================================

if ~exist('Outputs','dir'); mkdir('Outputs'); end

methods = {'JacobiAJD','RiemGD','RTR','BOOOM'};

%% 1) Objective values
ObjTable = table(loss_jacobi,loss_rg,loss_rtr,loss_booom,...
    'VariableNames',methods);

filename_obj = sprintf('Outputs/Output_AJD_p_%d_m_%d_objVal.csv',p,m);
writetable(ObjTable,filename_obj);

%% 2) Time per replicate
TimeTable = table(time_jacobi,time_rg,time_rtr,time_booom,...
    'VariableNames',methods);

filename_time = sprintf('Outputs/Output_AJD_p_%d_m_%d_time.csv',p,m);
writetable(TimeTable,filename_time);

%% 3) Summary file
mean_obj = mean(ObjMat);
se_obj   = std(ObjMat)/sqrt(R);

mean_time = mean(TiMat);
se_time   = std(TiMat)/sqrt(R);

SummaryMatrix = [mean_obj; se_obj; mean_time; se_time];

SummaryTable = array2table(SummaryMatrix,...
    'VariableNames',methods,...
    'RowNames',{'mean_obj','se_obj','mean_time','se_time'});

filename_summary = sprintf('Outputs/Output_AJD_p_%d_m_%d_summary.csv',p,m);
writetable(SummaryTable,filename_summary,'WriteRowNames',true);

fprintf('\nResults saved successfully.\n');
fprintf('  %s\n  %s\n  %s\n', filename_obj, filename_time, filename_summary);