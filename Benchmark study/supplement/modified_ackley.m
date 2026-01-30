function val = modified_ackley(O)
% MODIFIED_ACKLEY_CORR applies Ackley function to diagonal and off-diagonal elements.
% Input:
%   O : N x N column ortogonal matrix
% Output:
%   val1 : scalar Ackley function value of diagonal elements
%   val2 : scalar Ackley function value of off-diagonal elements
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


    % Ackley parameters
    a = 20;
    b = 0.2;
    c = 2 * pi;
    % length of diagonal elements
    d_D = numel(x1);
    % length of off-diagonal elements
    d_OD = numel(x2);

    % Ackley function for  diagonal part
    sum_sq_D = sum(x1.^2);
    sum_cos_D = sum(cos(c * x1));
    term1_D = -a * exp(-b * sqrt(sum_sq_D / d_D));
    term2_D = -exp(sum_cos_D / d_D);
    val1 = term1_D + term2_D + a + exp(1);


    % Ackley function for off diagonal part
    sum_sq_OD = sum(x2.^2);
    sum_cos_OD = sum(cos(c * x2));
    term1_OD = -a * exp(-b * sqrt(sum_sq_OD / d_OD));
    term2_OD = -exp(sum_cos_OD / d_OD);
    val2 = term1_OD + term2_OD + a + exp(1);

    % Sum of two Ackley functions (diagonal & off-diagonal)
    val = val1+val2;
end

