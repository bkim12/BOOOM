function V = varimax_value(A, R)
%VARIMAX_VALUE Kaiser varimax objective value V(R) for B = A*R.
% A: p x q loadings
% R: q x q orthogonal rotation
% V(R) = sum_j [ (1/p) sum_i B_ij^4 - ((1/p) sum_i B_ij^2)^2 ].

B = A * R;
p = size(B,1);

col2 = mean(B.^2, 1);     % 1 x q, (1/p) sum_i B_ij^2
col4 = mean(B.^4, 1);     % 1 x q, (1/p) sum_i B_ij^4

V = sum(col4 - col2.^2);
end