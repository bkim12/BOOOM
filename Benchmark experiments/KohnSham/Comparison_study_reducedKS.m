%% ============================================================
%  KS-inspired Reduced Rayleigh–Ritz Benchmark (Frozen KS Hamiltonian)
%  Manopt (RCG) vs BOOOM + exact eigen baseline
%  MATLAB 2021a compatible
%
%  Variable: Q ∈ R^{nred×p}, Q'Q = I
%  Objective: f(Q) = tr(Q' * Hred * Q),  Hred = B' * H* * B
%% ============================================================

clear; clc; close all;

addpath('./BOOOM/');
addpath(genpath('./supplement/'));
addpath(genpath('./supplement/manopt/'));
addpath(genpath('./supplement/kssolv2.0/'));

%% ------------------ BOOOM settings ------------------
BOOOM_parallel = 0;
runBOOOM = true;
maxtime_each = 3600;
TolFun1 = 1e-7;
MaxRuns = 2;

%% ------------------ Manopt settings ------------------
runMANOPT = true;
manopt_verbosity = 0;

%% ------------------ SETTINGS ------------------
rng(1,'twister');

nred = 50; % 20, 50, 80, 100
p    = 2;
R    = 10;

%% ------------------ STORAGE ------------------
f_eig   = zeros(R,1);
f_rcg   = nan(R,1);
f_booom = nan(R,1);

res_eig   = zeros(R,1);
res_rcg   = nan(R,1);
res_booom = nan(R,1);

gap_rcg   = nan(R,1);
gap_booom = nan(R,1);

time_eig   = zeros(R,1);
time_rcg   = nan(R,1);
time_booom = nan(R,1);

nfev_booom = nan(R,1);

%% ============================================================
% 0) Build KS system once
%% ============================================================

kssolvpptype('oncv');

a1 = Atom('H');
atomlist = [a1 a1];
C = 10*eye(3);
xyzlist = [1.5 0 0; 0 0 0];

mol = Molecule('supercell',C,'atomlist',atomlist,'xyzlist',xyzlist,...
    'ecutwfc',50.0,'name','h2');

options = setksopt();
[~,Hstar,X_scf,info_scf] = scf(mol,options);

Ustar = X_scf.psi;
Ng    = size(Ustar,1);
nocc  = sum(X_scf.occ > 0.5);

fprintf('\nKS setup complete.\n');
fprintf('SCF Etot = %.12f | Ng = %d | nocc = %d\n',info_scf.Etot,Ng,nocc);
fprintf('Benchmark variable: Q is %d x %d\n',nred,p);

%% ============================================================
%                 MONTE CARLO LOOP
%% ============================================================
for r = 1:R

    fprintf('\n=== Replicate %d / %d ===\n',r,R);

    %% 1) Reduced basis
    B = zeros(Ng,nred);

    k0 = size(Ustar,2);

    if k0 > nred
        error('nred must be >= number of SCF orbitals.');
    end

    B(:,1:k0) = Ustar;

    Z = randn(Ng,nred-k0);
    Z = Z - Ustar*(Ustar'*Z);

    [Qz,~] = qr(Z,0);

    B(:,k0+1:end) = Qz(:,1:(nred-k0));

    %% 2) Reduced Hamiltonian
    tic

    HB = zeros(Ng,nred);
    Xtmp = X_scf;

    for j = 1:nred
        Xtmp.psi = B(:,j);
        HXtmp = Hstar * Xtmp;
        HB(:,j) = HXtmp.psi;
    end

    Hred = B'*HB;
    Hred = 0.5*(Hred + Hred');

    fprintf('Built Hred in %.2f sec\n',toc);

    %% 3) Exact eigen baseline
    tic

    [V,D] = eig(Hred);
    [~,idx] = sort(diag(D),'ascend');

    V = V(:,idx);
    Q_eig = V(:,1:p);

    f_eig(r) = trace(Q_eig'*Hred*Q_eig);
    res_eig(r) = kkt_residual(Hred,Q_eig);
    time_eig(r) = toc;

    fprintf('EIG  f = %.12f | res = %.2e\n',f_eig(r),res_eig(r));

    %% 4) Objective + gradient

    costfun = @(Q) trace(Q'*Hred*Q);
    egrad   = @(Q) 2*(Hred*Q);

    [Q0,~] = qr(randn(nred,p),0);

    %% =========================================================
    %% Manopt RCG
    %% =========================================================
    if runMANOPT

        manifold = stiefelfactory(nred,p);

        problem.M = manifold;
        problem.cost  = costfun;
        problem.egrad = egrad;

        opts = struct('verbosity',manopt_verbosity);

        tic
        Q_rcg = conjugategradient(problem,Q0,opts);
        time_rcg(r) = toc;

        f_rcg(r) = costfun(Q_rcg);
        res_rcg(r) = kkt_residual(Hred,Q_rcg);
        gap_rcg(r) = f_rcg(r) - f_eig(r);

        fprintf('RCG  f = %.12f | gap = %.3e | res = %.2e | time = %.2f\n',...
            f_rcg(r),gap_rcg(r),res_rcg(r),time_rcg(r));

    end

    %% =========================================================
    %% BOOOM
    %% =========================================================
    if runBOOOM

        counter = Counter();

        objFun_counted = @(Q) counted_cost(Q,Hred,counter);

        if BOOOM_parallel == 1

            [Q_boom,fval_boom,comp_time_boom] = ...
                BOOOMparallel(objFun_counted,Q0,maxtime_each,...
                MaxRuns,[],[],[],TolFun1);

        else

            [Q_boom,fval_boom,comp_time_boom] = ...
                BOOOM(objFun_counted,Q0,maxtime_each,...
                MaxRuns,[],[],[],TolFun1);

        end

        f_booom(r) = fval_boom;
        res_booom(r) = kkt_residual(Hred,Q_boom);
        gap_booom(r) = f_booom(r) - f_eig(r);
        nfev_booom(r) = counter.n;
        time_booom(r) = comp_time_boom;

        fprintf('BOOM f = %.12f | gap = %.3e | res = %.2e | fev = %d | time = %.2f\n',...
            f_booom(r),gap_booom(r),res_booom(r),nfev_booom(r),comp_time_boom);

    end

end

%% ============================================================
%                      SUMMARY
%% ============================================================

fprintf('\n================ SUMMARY ================\n');

fprintf('EIG  mean f = %.12f (SE=%.3e) | mean res = %.2e\n',...
    mean(f_eig),std(f_eig)/sqrt(R),mean(res_eig));

if runMANOPT
    fprintf('RCG  mean f = %.12f | mean gap = %.3e | mean res = %.2e | mean time = %.2f\n',...
        mean(f_rcg,'omitnan'),mean(gap_rcg,'omitnan'),...
        mean(res_rcg,'omitnan'),mean(time_rcg,'omitnan'));
end

if runBOOOM
    fprintf('BOOM mean f = %.12f | mean gap = %.3e | mean res = %.2e | mean fev = %.1f | mean time = %.2f\n',...
        mean(f_booom,'omitnan'),mean(gap_booom,'omitnan'),...
        mean(res_booom,'omitnan'),mean(nfev_booom,'omitnan'),...
        mean(time_booom,'omitnan'));
end

%% ============================================================
%                    SAVE RESULTS
%% ============================================================

if ~exist('Outputs','dir'); mkdir('Outputs'); end

methods = {'EIG','RCG','BOOOM'};

ObjTable = table(real(f_eig),real(f_rcg),real(f_booom),...
    'VariableNames',methods);

filename_obj = sprintf('Outputs/Output_KS_RR_nred_%d_p_%d_objVal.csv',nred,p);
writetable(ObjTable,filename_obj);

GapTable = table(zeros(R,1),real(gap_rcg),real(gap_booom),...
    'VariableNames',methods);

filename_gap = sprintf('Outputs/Output_KS_RR_nred_%d_p_%d_gap.csv',nred,p);
writetable(GapTable,filename_gap);

ResTable = table(real(res_eig),real(res_rcg),real(res_booom),...
    'VariableNames',methods);

filename_res = sprintf('Outputs/Output_KS_RR_nred_%d_p_%d_residual.csv',nred,p);
writetable(ResTable,filename_res);

TimeTable = table(time_eig,time_rcg,time_booom,'VariableNames',methods);

filename_time = sprintf('Outputs/Output_KS_RR_nred_%d_p_%d_time.csv',nred,p);
writetable(TimeTable,filename_time);

FevTable = table(nfev_booom,'VariableNames',{'BOOOM_fev'});

filename_fev = sprintf('Outputs/Output_KS_RR_nred_%d_p_%d_fev.csv',nred,p);
writetable(FevTable,filename_fev);

fprintf('\nResults saved successfully.\n');