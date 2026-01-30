function [M] = create_PSD(d)
    % create a Postive SemiDefinite matrix (eg.correlation matrix)

    % generate a random matrix A
    A = randn(d,d);
    % covariance matrix
    P = A'*A;

    % normalize to get correlation matrix
    D = sqrt(diag(P));
    C = P ./ (D * D');
    
    % ensure symmetry (in case of floating point precision errors)
    M= (C+C')/2;
end
    