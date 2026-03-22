function [X,L,S] =generate_data(p,d,r)
% generate sparsity data.
% Input:
%  p : number of rows, d : number of columns, r : rank
% Output:
%  X : sprase data (pxd)



%%% generate row rank matrix
A = normrnd(0,1,[p,d]);
[U,D,V] = svd(A);

% pxr
U_A = U(:,1:r);  

% rxr
if r ==1
    D_L = 2;
else
    D_L= diag([2,1+(r-2:-1:1)./(r-1),1]);
end

% rxd
V_A = V(:,1:r)';

% L
L = U_A*D_L*V_A;


%%% generate sparse matrix

% generate M from standard cauchy distribution
M = trnd(1,p,d);
% generate B from bernoulli distribution
B = binornd(1,0.2,p,d);

S = M.*B; 

%%% X 

X = L+S; 


end