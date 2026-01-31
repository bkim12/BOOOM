function [metric1,metric2] = sparsity_metric(Q)
    % Q: Orthonomal matrix pxd
    
    
    % calculating l2 norm of rows of Q matrix, 
    % if a norm for a row <10^-2, it is considered zero 
    non_zero_rows = (sqrt(sum(Q.^2,2)) > 10^-2);
    total_non_zero_rows = sum(non_zero_rows);
    
    % metric1: ratio of number of non zero rows to total number of rows
    metric1 = sum(total_non_zero_rows)/size(Q,1);
    % metric2: ratio of zero elements to total number of elements out of non zero rows
    metric2 = sum(abs(Q(non_zero_rows,:)) < (10^-2),"all")./ (total_non_zero_rows*size(Q,2));

end
