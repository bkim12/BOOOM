%% ============================================================
%  VARIMAX Rotation Simulation Study
%  rotatefactors (baseline) vs BOOOM
%  MATLAB 2021a compatible
%% ============================================================

clear; clc; close all;

addpath('./supplement/'); 
addpath('./BOOOM/');          % your BOOOM folder
% NOTE: rotatefactors is built-in (Statistics and Machine Learning Toolbox)

% If you use amari_distance.m from earlier ICA code, keep it on path:
% addpath('./helpers/');

%% ------------------ BOOOM settings ------------------
BOOOM_parallel = 0;    % 1 = parallel, 0 = non-parallel
runBOOOM = true;
maxtime_each = 3600;    % seconds (set whatever you want)
TolFun1 = 1e-9;
MaxRuns = 2;

%% ------------------ SETTINGS ------------------
rng(1,'twister');
% (30,5), (60,5), (50,10), (100,10),(80,20), (150,20),(120,30), (200,30)
p = 30;       % number of observed variables (rows of loadings)
q = 5;       % number of factors/components (columns)
R = 10;       % Monte Carlo replicates

%% ------------------ STORAGE ------------------
loss_rotatefactors = zeros(R,1);
loss_booom         = zeros(R,1);

amari_rotatefactors = zeros(R,1);
amari_booom         = zeros(R,1);

time_rotatefactors = zeros(R,1);
time_booom         = zeros(R,1);

%% ============================================================
%                 MONTE CARLO LOOP
%% ============================================================
for r = 1:R
    fprintf('\n=== Replicate %d / %d ===\n', r, R);

    %% 1) Generate simple-structure true loadings B0 (p x q)
    % Each variable loads mainly on one factor (sparse/simple structure)
    B0 = zeros(p,q);
    mainFactor = randi(q, p, 1);
    for i = 1:p
        j = mainFactor(i);
        mag = 0.8 + 0.4*rand();          % in [0.8,1.2]
        sgn = sign(randn());
        B0(i,j) = sgn * mag;

        % small cross-loadings to make it realistic (optional)
        % (keeps varimax nontrivial)
        idx = randperm(q, 2);
        for kk = 1:numel(idx)
            if idx(kk) ~= j
                B0(i, idx(kk)) = 0.05 * randn();
            end
        end
    end

    % Standardize columns (optional; makes scale comparable)
    B0 = B0 ./ max(vecnorm(B0,2,1), 1e-12);

    %% 2) Random true orthogonal rotation Rtrue (q x q)
    [Qtmp,~] = qr(randn(q,q), 0);
    Rtrue = Qtmp;

    % Observed loading matrix A is rotated version of B0
    % So the optimizer should recover Rtrue (up to sign/permutation)
    A = B0 * Rtrue';

    %% 3) Define Varimax objective V(R) and minimization loss = -V(R)
    % B = A*R
    % V(R) = sum_j [ (1/p) sum_i B_ij^4 - ((1/p) sum_i B_ij^2)^2 ]
    lossfun = @(Rmat) -varimax_value(A, Rmat);

    %% ============================================================
    %  BASELINE: MATLAB rotatefactors (varimax)
    %% ============================================================
    tic;
    % rotatefactors returns rotated loadings and rotation matrix T:
    % B_hat = A * T
    [B_hat, T_hat] = rotatefactors(A, 'Method', 'varimax');
    time_rotatefactors(r) = toc;

    % Safety: enforce orthogonal (numerical)
    [U,~,V] = svd(T_hat,'econ');
    T_hat = U*V';

    loss_rotatefactors(r)  = lossfun(T_hat);

    % Rotation recovery metric (Amari on Rhat*Rtrue')
    amari_rotatefactors(r) = amari_distance(T_hat * Rtrue');

    fprintf('rotatefactors loss = %.6f | Amari = %.4f\n', ...
        loss_rotatefactors(r), amari_rotatefactors(r));

    %% ============================================================
    %  BOOOM
    %% ============================================================
    if runBOOOM
        d = q;  % orthogonal q x q

        [Q_initial, ~] = qr(randn(q,d), 0);
        objFun_min = @(Q) lossfun(Q);

        if BOOOM_parallel == 1
            [Q_BOOOM, fval_BOOOM, comp_time_BOOOM] = ...
                BOOOMparallel(objFun_min, Q_initial, maxtime_each, ...
                MaxRuns, [], [], [], TolFun1);
        else
            [Q_BOOOM, fval_BOOOM, comp_time_BOOOM] = ...
                BOOOM(objFun_min, Q_initial, maxtime_each, ...
                MaxRuns, [], [], [], TolFun1);
        end

        time_booom(r) = comp_time_BOOOM;
        loss_booom(r) = fval_BOOOM;

        amari_booom(r) = amari_distance(Q_BOOOM * Rtrue');

        fprintf('BOOOM loss        = %.6f | Amari = %.4f | time = %.2f sec\n', ...
            loss_booom(r), amari_booom(r), comp_time_BOOOM);
    end
end

%% ============================================================
%                      SUMMARY
%% ============================================================
fprintf('\n================ SUMMARY ================\n');

fprintf('rotatefactors mean loss  = %.6f (SE = %.6f)\n', ...
    mean(loss_rotatefactors), std(loss_rotatefactors)/sqrt(R));
%fprintf('rotatefactors mean Amari = %.6f (SE = %.6f)\n', ...
    %mean(amari_rotatefactors), std(amari_rotatefactors)/sqrt(R));

if runBOOOM
    fprintf('BOOOM mean loss          = %.6f (SE = %.6f)\n', ...
        mean(loss_booom), std(loss_booom)/sqrt(R));
    %fprintf('BOOOM mean Amari         = %.6f (SE = %.6f)\n', ...
       % mean(amari_booom), std(amari_booom)/sqrt(R));
end

%% ============================================================
%                    SAVE RESULTS TO FILES
%% ============================================================
if ~exist('Outputs','dir'); mkdir('Outputs'); end

methods = {'rotatefactors','BOOOM'};

% 1) objVal (min loss achieved per replicate)
ObjTable = table(loss_rotatefactors, loss_booom, 'VariableNames', methods);
filename_obj = sprintf('Outputs/Output_Varimax_p_%d_q_%d_objVal.csv', p, q);
writetable(ObjTable, filename_obj);

% 2) AMARI (rotation recovery error per replicate)
AmariTable = table(amari_rotatefactors, amari_booom, 'VariableNames', methods);
filename_amari = sprintf('Outputs/Output_Varimax_p_%d_q_%d_AMARI.csv', p, q);
writetable(AmariTable, filename_amari);

% 3) Summary file: mean/se for obj, mean/se for amari, mean/se for time
mean_obj   = [mean(loss_rotatefactors), mean(loss_booom)];
se_obj     = [std(loss_rotatefactors)/sqrt(R), std(loss_booom)/sqrt(R)];

mean_amari = [mean(amari_rotatefactors), mean(amari_booom)];
se_amari   = [std(amari_rotatefactors)/sqrt(R), std(amari_booom)/sqrt(R)];

mean_time  = [mean(time_rotatefactors), mean(time_booom)];
se_time    = [std(time_rotatefactors)/sqrt(R), std(time_booom)/sqrt(R)];

SummaryMatrix = [mean_obj; se_obj; mean_amari; se_amari; mean_time; se_time];

SummaryTable = array2table(SummaryMatrix, ...
    'VariableNames', methods, ...
    'RowNames', {'mean_obj','se_obj','mean_amari','se_amari','mean_time','se_time'});

filename_summary = sprintf('Outputs/Output_Varimax_p_%d_q_%d_summary.csv', p, q);
writetable(SummaryTable, filename_summary, 'WriteRowNames', true);

fprintf('\nResults saved successfully.\n');
fprintf('  %s\n  %s\n  %s\n', filename_obj, filename_amari, filename_summary);