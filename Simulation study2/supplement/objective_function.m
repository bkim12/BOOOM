function val = objective_function(X,Q,lambda)
    % obejctive function: min rank(L) +lambda(S)
    % X: data
    % Q: Q orthonomal matrix
    % L = X*Q*Q', S = X-X*Q*Q'


    % low rank (estimated with nuclear norm)
    L = (X*Q)*Q';
    [~,sigma,~] = svd(L);
    val1= sum(diag(sigma));
    

    % sparsity (estimated with element wise l 1 norm)
    I = eye(size(X,2));
    S = X*(I-Q*Q');
    norm_1 = sum(abs(S),"all");
    val2 = lambda*norm_1;


    % sum val1 and val2

    val = val1+val2;
end