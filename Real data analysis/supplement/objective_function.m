function val = objective_function(X,Q,Y,lambdas)
    % X: Data,nxp
    % Q: Orthonomal matrix pxd
    % Y: Response variable, nx1 (healthy:0, cancer:1)
    % lambdas: penality combination vector (1st: labmda1, 2nd: lambda2)
    lambda1 = lambdas(1);
    lambda2 = lambdas(2);

    %%% frobenius norm term
    A = X-(X*Q)*Q';
    term1 = norm(A,"fro")^2;

    %%% l_2,1 norm term
    term2 = lambda1*sum(sqrt(sum(Q.^2,2)));

    %%% Fisher discriminant loss term 
    % index for healthy and cancer subjects
    I0 = (Y==0); % healthy subjects
    I1 = (Y==1); % cancer subjects
    projected_matrix = X*Q;
    
    % count the number of subjects 
    n0 = sum(I0);
    n1 = sum(I1);
    
    % calculate projected matrix 
    projected_matrix_I0 = projected_matrix(I0,:);
    projected_matrix_I1 = projected_matrix(I1,:);

    % calculate mu0 (1xd) and mu1 (1xd) vectors
    mu0 = sum(projected_matrix_I0)/n0;
    mu1 = sum(projected_matrix_I1)/n1;


    % Fisher discriminant loss 
    % term3 = lambda2*(sum(sqrt(sum((projected_matrix_I0-mu0).^2,2))) + ...
    %     sum(sqrt(sum((projected_matrix_I1-mu1).^2,2))));
    term3 = lambda2*(sum(sum((projected_matrix_I0-mu0).^2,2)) + ...
        sum(sum((projected_matrix_I1-mu1).^2,2)));

    %%% sum of three terms
    val = term1 + term2 + term3;

end
