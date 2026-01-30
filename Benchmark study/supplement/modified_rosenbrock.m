function val = modified_rosenbrock(O)
% MODIFIED_ROSENBROCK applies Rosenbrock function to diagonal and off-diagonal elements.
% Input:
%   O : N x N column ortogonal matrix
% Output:
%   val1 : scalar Rosenbrock function value of diagonal elements
%   val2 : scalar Rosenbrock function value of off-diagonal elements
%   val  : sum of val1 and val2 


    % Dimension of input square column ortogonal matrix
    N = size(O,1);

    err = norm(O' * O - eye(N), 'fro');

    if err > 1e-8
        % error('Input matrix must be a column orthogonal matrix.');
        warning('Input is far from orthogonal.');
    end

    
    % Extract diagonal element
    x1 = (diag(O));  % Column vector of length N


    % Extract off-diagonal elements
    off_diag_mask = ~eye(N);
    x2 = (O(off_diag_mask)+1);  % Column vector of length N^2 - N


    % length of diagonal elements
    d_D = numel(x1);
    % length of off-diagonal elements
    d_OD = numel(x2);


    % rosenbrock function for diagonal part
    slice_D_2 = x1(2:d_D);
    slice_D_1 = x1(1:d_D-1);
    
    term1_D = sum((slice_D_2 - slice_D_1.^2).^2);
    term2_D = sum((slice_D_1-1).^2);

    val1 = 100*term1_D +term2_D;

    % rosenbrock function for off-diagonal part
    slice_OD_2 = x2(2:d_OD);
    slice_OD_1 = x2(1:d_OD-1);
    
    term1_OD = sum((slice_OD_2 - slice_OD_1.^2).^2);
    term2_OD = sum((slice_OD_1-1).^2);

    val2 = 100*term1_OD +term2_OD;
    

    % Sum of two Rosenbrock functions (diagonal & off-diagonal)
    val = val1+val2;
end

