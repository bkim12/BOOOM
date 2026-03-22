function M = eval_metrics(X,L,S, L_hat, S_hat)
% generate sparsity data.
%%%%% Input:
%  X : original data
%  L : original low rank data
%  S : original sparsity data
%  L_hat : estimated low rank data
%  S_hat : estimated sparsity data


% M.X, M.L, M.S each contain: RMSE, rRMSE, MAE, rMAE

X_hat = L_hat + S_hat;

M.X = metrics_output(X, X_hat);
M.L = metrics_output(L, L_hat);
M.S = metrics_output(S, S_hat);
end