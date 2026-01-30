function [c, ceq] = orthogonalityConstraint(x, P, Q)
    % constraint for column orthonomal matrix
    O = reshape(x, P, Q);  % reshape back into P×Q matrix
    ceq_matrix = O' * O - eye(P);  % Q x Q matrix: columns orthonormal
    ceq = reshape(ceq_matrix, [], 1);  % Vectorize constraints for fmincon
    c = [];  % no inequality constraints
end