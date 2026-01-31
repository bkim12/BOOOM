function rate = misclassification(X,Q,Y)
    % X: Data,nxp
    % Q: Orthonomal matrix pxd
    % Y: Response variable, nx1 (healthy:0, cancer:1)

    %%%%% misclassification

    % index for healthy and cancer subjects
    I0 = (Y==0); % healthy subjects
    I1 = (Y==1); % cancer subjects
    
    % count the number of subjects 
    n0 = sum(I0);
    n1 = sum(I1);
    
    % projected matrix
    XQ = X*Q;

    % calculate projected matrix 
    projected_matrix_I0 = XQ(I0,:);
    projected_matrix_I1 = XQ(I1,:);
    
    % calculate mu0 (1xd) and mu1 (1xd) vectors
    mu0 = sum(projected_matrix_I0)/n0;
    mu1 = sum(projected_matrix_I1)/n1;
    
    % euclidean distance between  XH and mu0, and mu1
    dist_mu0 = sqrt(sum((XQ-mu0).^2,2));
    dist_mu1 = sqrt(sum((XQ-mu1).^2,2));
    
    % if distance from mu1 < distance from mu0, classify it as 1 (cancer)
    % otherwise (distance from mu0 < distance from mu1) classify it as 0
    % (healthy)
    Y_hat = (dist_mu1 < dist_mu0);
    
    % misclassification rate
    rate = sum(Y_hat ~= Y)/size(Y,1);

end
