function [W, fval] = ajd_jacobi(C, nsweeps, tol)
% AJD Jacobi/Givens sweeps for minimizing sum_k ||offdiag(W' Ck W)||_F^2
% C: p x p x m symmetric
[p,~,m] = size(C);
W = eye(p);

for sweep = 1:nsweeps
    max_change = 0;

    for i = 1:p-1
        for j = i+1:p
            % Build 2x2 criterion for rotating (i,j)
            g11 = 0; g22 = 0; g12 = 0; g21 = 0;

            for k = 1:m
                M = W' * C(:,:,k) * W;

                a = M(i,i); b = M(j,j);
                c = M(i,j) + M(j,i); % symmetric so 2*M(i,j)

                % Following classic AJD Jacobi update heuristics:
                g11 = g11 + (a - b);
                g12 = g12 + c;
            end

            % Compute rotation angle
            theta = 0.5 * atan2(g12, g11 + eps);
            cth = cos(theta);
            sth = sin(theta);

            if abs(theta) > tol
                max_change = max(max_change, abs(theta));
                G = eye(p);
                G([i j],[i j]) = [cth -sth; sth cth];
                W = W * G;
            end
        end
    end

    if max_change < tol
        break
    end
end

% objective value
fval = 0;
for k=1:m
    M = W' * C(:,:,k) * W;
    M = M - diag(diag(M));
    fval = fval + sum(M(:).^2);
end
end