function f = ajd_offdiag_objective(C, W)
%AJD_OFFDIAG_OBJECTIVE  Sum of squared off-diagonal energy after rotation.
% C: p x p x m symmetric matrices
% W: p x p orthogonal
% f(W) = sum_k || offdiag(W' C_k W) ||_F^2

[p,~,m] = size(C);
f = 0;
for k = 1:m
    M = W' * C(:,:,k) * W;
    M = M - diag(diag(M));    % offdiag
    f = f + sum(M(:).^2);
end
end