function val = objective_function(M,U,min_max)
    % obejctive function (max trace(U'M U))
    % M: k many PSD
    % U: optimal solution
    % min_max: define if an optimization method is designed to find a
    %          minimum or maximum value
    % If the optimization method solves for the minimum, the objective function will
    % minimize the objective function. So, the output value needs to be taken
    % by a negative sign in order to correctly represent the desired maximum value.
    % 

    k = size(M,1);

    val = 0;
    for i = 1:k
        M_i = M{k,1};
        UMU = U'*M_i*U;
        val = UMU(k,k) +val;
    end

    if strcmp(min_max,'min')
        val = -val;
    else
        val;
    end

end