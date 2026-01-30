function outputs = metrics_output(T, T_hat)
%%%%% Input:
% T : Original data
% T_hat : estimated data

%%%%% Output:
%  RMSE   : RMSE
%  R_RMSE : relative RMSE
%  MAE    : MAE
%  R_MAE  : relative MAE



Diff = T - T_hat;

% RMSE (Frobenius) and relative RMSE
outputs.RMSE  = norm(Diff, 'fro') /sqrt(numel(T));
outputs.R_RMSE = norm(Diff, 'fro') /norm(T, 'fro');      

% MAE and relative MAE
outputs.MAE   = mean(abs(Diff), 'all');
outputs.R_MAE  = mean(abs(Diff), 'all') /mean(abs(T), 'all');
end