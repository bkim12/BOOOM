%% ============================================================
%  ICA Simulation Study
%  FastICA vs BOOOM (placeholder)
%  MATLAB 2021a compatible
% =============================================================

clear; clc; close all;

addpath('./supplement/FastICA_25/');
addpath('./supplement/');
addpath('./BOOOM/');
addpath(genpath('./supplement/eeglab/'));
addpath(genpath('./supplement/picard-master/matlab_octave/'));

%% ------------------ BOOOM setttings -----------

BOOOM_parallel = 0; % 1 = parallel, 0 = non-parallel
runBOOOM = true;   % set to true once BOOOM is ready
maxtime_each = 60;
TolFun1 = 10^(-9);
MaxRuns = 2;

%% ------------------ SETTINGS ------------------
rng(1,'twister');

p  = 50;        % dimension %(20,50), (20,200), (50,125), (50,500).
n  = 500;       % sample size
R  = 10;        % number of Monte Carlo replicates
a1 = 1;         % logcosh parameter



%% ------------------ STORAGE ------------------
loss_fastica  = zeros(R,1);
loss_booom    = zeros(R,1);

amari_fastica = zeros(R,1);
amari_booom   = zeros(R,1);

loss_runica    = zeros(R,1);
amari_runica   = zeros(R,1);

loss_picard    = zeros(R,1);
amari_picard   = zeros(R,1);

time_fastica = zeros(R,1);
time_runica  = zeros(R,1);
time_picard  = zeros(R,1);
time_booom   = zeros(R,1);

%% ============================================================
%                 MONTE CARLO LOOP
%% ============================================================

for r = 1:R
    
    fprintf('\n=== Replicate %d / %d ===\n', r, R);
    
    %% ------------------ 1. Generate Sources ------------------
    S = zeros(p,n);
    
    for i = 1:p
        if mod(i,3)==1
            % Laplace (super-Gaussian)
            u = rand(1,n)-0.5;
            S(i,:) = - sign(u).*log(1-2*abs(u));
        elseif mod(i,3)==2
            % Student-t
            S(i,:) = trnd(3,1,n);
        else
            % Uniform (sub-Gaussian)
            S(i,:) = (rand(1,n)-0.5)*sqrt(12);
        end
    end
    
    % Standardize
    S = S - mean(S,2);
    S = S ./ std(S,0,2);
    
    %% ------------------ 2. Mixing ------------------
    [U,~] = qr(randn(p));
    [V,~] = qr(randn(p));
    svals = logspace(0,1,p);   % moderate conditioning
    Atrue = U * diag(svals) * V';
    
    X = Atrue * S;
    
    %% ------------------ 3. Whitening ------------------
    Xc = X - mean(X,2);
    C  = (Xc*Xc')/n;
    
    [E,D] = eig((C+C')/2);
    d = diag(D);
    Vwhite = diag(1./sqrt(d)) * E';
    Xw = Vwhite * Xc;
    
    %% ------------------ 4. Define Loss ------------------
    % L(W) = mean_t sum_i log cosh(a1 * (w_i' x_t))
    
    lossfun = @(W) mean( sum( log(cosh(a1*(W*Xw))), 1 ) );
    
    %% ============================================================
    %                  FASTICA
    %% ============================================================
    tic;
    [icasig, Aest, West] = fastica(X, ...
        'whiteSig', Xw, ...
        'whiteMat', Vwhite, ...
        'dewhiteMat', pinv(Vwhite), ...
        'approach','symm', ...
        'g','tanh', ...
        'a1',a1, ...
        'verbose','off', ...
        'displayMode','off');
    time_fastica(r) = toc;
    
    % Project to nearest orthogonal (numerical safety)
    [Uf,~,Vf] = svd(West,'econ');
    Wf = Uf*Vf';
    
    loss_fastica(r) = lossfun(Wf);
    
    % Amari distance
    M = Wf * (Vwhite*Atrue);
    amari_fastica(r) = amari_distance(M);
    
    fprintf('FastICA loss = %.6f | Amari = %.4f\n', ...
        loss_fastica(r), amari_fastica(r));
    
    %% ============================================================
    %                  INFOMAX (runica)
    %% ============================================================
    
    % runica expects data in channels x samples format
    tic;
    [weights, sphere] = runica(Xw, 'verbose','off');
    time_runica(r) = toc;
    
    % Effective unmixing matrix
    W_runica = weights * sphere;
    
    % Project to nearest orthogonal (fair comparison)
    [Ur,~,Vr] = svd(W_runica,'econ');
    W_runica = Ur * Vr';
    
    % Evaluate loss
    loss_runica(r) = lossfun(W_runica);
    
    % Amari distance
    amari_runica(r) = amari_distance(W_runica * (Vwhite*Atrue));
    
    fprintf('RunICA loss = %.6f | Amari = %.4f\n', ...
        loss_runica(r), amari_runica(r));
    
    %% ============================================================
    %                  PICARD (fixed logcosh score)
    %% ============================================================
    
    % Use standard Picard with distribution = 'logcosh'
    % This aligns the score function with your logcosh objective
    % Xw is already whitened, so set whiten = false
    
    try
        tic;
        [Y_picard, W_picard] = picard(Xw, ...
            'mode',         'standard', ...
            'distribution', 'logcosh', ...
            'whiten',       false, ...
            'centering',    false, ...
            'verbose',      false, ...
            'maxiter',      200, ...
            'tol',          1e-8);
        time_picard(r) = toc;
    catch ME
        error('Picard failed: %s', ME.message);
    end
    
    % Project to nearest orthogonal (to match BOOOM constraint W ∈ O(p))
    [Up,~,Vp] = svd(W_picard,'econ');
    W_picard = Up * Vp';
    
    % Evaluate same external loss and Amari
    loss_picard(r)  = lossfun(W_picard);
    amari_picard(r) = amari_distance(W_picard * (Vwhite*Atrue));
    
    fprintf('Picard (logcosh) loss = %.6f | Amari = %.4f\n', ...
        loss_picard(r), amari_picard(r));
    %% ============================================================
    %                  BOOOM (actual call)
    %% ============================================================
    
    if runBOOOM
        
        d = p;   % square orthogonal case
        
        % Initial orthogonal matrix
        [Q_initial, ~] = qr(randn(p,d), 0);
        
        % Define objective in BOOOM format
        objFun_min = @(Q) -lossfun(Q);
        
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
        % Store results
        loss_booom(r) = -fval_BOOOM;
        
        % Amari distance
        amari_booom(r) = amari_distance(Q_BOOOM * (Vwhite*Atrue));
        
        fprintf('BOOOM loss = %.6f | Amari = %.4f | time = %.2f sec\n', ...
            loss_booom(r), amari_booom(r), comp_time_BOOOM);
        
    end
end

%% ============================================================
%                      SUMMARY
%% ============================================================

fprintf('\n================ SUMMARY ================\n');
fprintf('FastICA mean loss   = %.6f (SE = %.6f)\n', ...
    mean(loss_fastica), std(loss_fastica)/sqrt(R));
%fprintf('FastICA median loss = %.6f\n', median(loss_fastica));
fprintf('FastICA mean Amari  = %.6f (SE = %.6f)\n', ...
    mean(amari_fastica), std(amari_fastica)/sqrt(R));

fprintf('RunICA mean loss    = %.6f (SE = %.6f)\n', ...
    mean(loss_runica), std(loss_runica)/sqrt(R));
%fprintf('RunICA median loss  = %.6f\n', median(loss_runica));
fprintf('RunICA mean Amari   = %.6f (SE = %.6f)\n', ...
    mean(amari_runica), std(amari_runica)/sqrt(R));

fprintf('Picard mean loss    = %.6f (SE = %.6f)\n', ...
    mean(loss_picard), std(loss_picard)/sqrt(R));
%fprintf('Picard median loss  = %.6f\n', median(loss_picard));
fprintf('Picard mean Amari   = %.6f (SE = %.6f)\n', ...
    mean(amari_picard), std(amari_picard)/sqrt(R));

if runBOOOM
    fprintf('BOOOM mean loss     = %.6f (SE = %.6f)\n', ...
        mean(loss_booom), std(loss_booom)/sqrt(R));
    %fprintf('BOOOM median loss   = %.6f\n', median(loss_booom));
    fprintf('BOOOM mean Amari  = %.6f (SE = %.6f)\n', ...
        mean(amari_booom), std(amari_booom)/sqrt(R));
end


%% ============================================================
%                    SAVE RESULTS TO FILES
%% ============================================================

methods = {'FastICA','RunICA','Picard','BOOOM'};

%% -------- 1) Objective values file --------
ObjTable = table( ...
    loss_fastica, ...
    loss_runica, ...
    loss_picard, ...
    loss_booom, ...
    'VariableNames', methods);

filename_obj = sprintf('Outputs/Output_ICA_p_%d_n_%d_objVal.csv', p, n);
writetable(ObjTable, filename_obj);

%% -------- 2) Amari values file --------
AmariTable = table( ...
    amari_fastica, ...
    amari_runica, ...
    amari_picard, ...
    amari_booom, ...
    'VariableNames', methods);

filename_amari = sprintf('Outputs/Output_ICA_p_%d_n_%d_AMARI.csv', p, n);
writetable(AmariTable, filename_amari);

%% -------- 3) Summary file --------

mean_obj = [mean(loss_fastica), ...
    mean(loss_runica), ...
    mean(loss_picard), ...
    mean(loss_booom)];

se_obj = [std(loss_fastica)/sqrt(R), ...
    std(loss_runica)/sqrt(R), ...
    std(loss_picard)/sqrt(R), ...
    std(loss_booom)/sqrt(R)];

mean_amari = [mean(amari_fastica), ...
    mean(amari_runica), ...
    mean(amari_picard), ...
    mean(amari_booom)];

se_amari = [std(amari_fastica)/sqrt(R), ...
    std(amari_runica)/sqrt(R), ...
    std(amari_picard)/sqrt(R), ...
    std(amari_booom)/sqrt(R)];

mean_time = [mean(time_fastica), ...
    mean(time_runica), ...
    mean(time_picard), ...
    mean(time_booom)];

se_time = [std(time_fastica)/sqrt(R), ...
    std(time_runica)/sqrt(R), ...
    std(time_picard)/sqrt(R), ...
    std(time_booom)/sqrt(R)];

SummaryMatrix = [ ...
    mean_obj;
    se_obj;
    mean_amari;
    se_amari;
    mean_time;
    se_time ];

SummaryTable = array2table(SummaryMatrix, ...
    'VariableNames', methods, ...
    'RowNames', {'mean_obj','se_obj','mean_amari','se_amari','mean_time','se_time'});

filename_summary = sprintf('Outputs/Output_ICA_p_%d_n_%d_summary.csv', p, n);
writetable(SummaryTable, filename_summary, 'WriteRowNames', true);

fprintf('\nResults saved successfully.\n');
