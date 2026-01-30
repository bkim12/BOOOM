function val = modified_rastrigin(O)
% MODIFIED_RASTRIGIN applies rastrigin function to diagonal and off-diagonal elements.
% Input:
%   O : N x N column ortogonal matrix
% Output:
%   val1 : scalar rastrigin function value of diagonal elements
%   val2 : scalar rastrigin function value of off-diagonal elements
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


    % rastrigin parameters
    a = 10;
    b = 2 * pi;

    % length of diagonal elements
    d_D = numel(x1);
    % length of off-diagonal elements
    d_OD = numel(x2);

    % rastrigin function for diagonal part
    sq_D = x1.^2;
    cos_D = cos(b * x1);

    summation_term_D = sum(sq_D - a*cos_D);
    val1 = a*d_D + summation_term_D;

    % rastrigin function for off-diagonal part
    sq_OD = x2.^2;
    cos_OD = cos(b * x2);

    summation_term_OD = sum(sq_OD - a*cos_OD);
    val2 = a*d_OD + summation_term_OD;

    % Sum of two Ackley functions (diagonal & off-diagonal)
    val = val1+val2;
end

