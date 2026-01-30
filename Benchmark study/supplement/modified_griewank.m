function val = modified_griewank(O)
% MODIFIED_GRIEWANK applies Griewank function to diagonal and off-diagonal elements.
% Input:
%   O : N x N column ortogonal matrix
% Output:
%   val1 : scalar Griewank function value of diagonal elements
%   val2 : scalar Griewank function value of off-diagonal elements
%   val  : sum of val1 and val2 


    % Dimension of input square column ortogonal matrix
    N = size(O,1);

    err = norm(O' * O - eye(N), 'fro');

    if err > 1e-8
        % error('Input matrix must be a column orthogonal matrix.');
        warning('Input is far from orthogonal.');
    end

    
    % Extract diagonal element
    x1 = 10*(diag(O)-1);  % Column vector of length N


    % Extract off-diagonal elements
    off_diag_mask = ~eye(N);
    x2 = 10*O(off_diag_mask);  % Column vector of length N^2 - N


    % length of diagonal elements
    d_D = numel(x1);
    % length of off-diagonal elements
    d_OD = numel(x2);


    % Griewank function for  diagonal part
    sum_sq_D = sum(x1.^2);
    prod_cos_i_D = prod(cos(x1./(1:d_D)'));

    val1 = 1 + (1/4000)*sum_sq_D - prod_cos_i_D;
    


    % Ackley function for off diagonal part
    sum_sq_OD = sum(x2.^2);
    prod_cos_i_OD = prod(cos(x2./(1:d_OD)'));

    val2 = 1 + (1/4000)*sum_sq_OD - prod_cos_i_OD;

    % Sum of two Ackley functions (diagonal & off-diagonal)
    val = val1+val2;
end

