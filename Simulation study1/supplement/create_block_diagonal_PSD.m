function M = create_block_diagonal_PSD(d, num_blocks)
    % Create a block diagonal matrix with correlation matrix blocks.
    % d: Total size of the matrix (e.g., 10 for 10x10 matrix)
    % num_blocks: Number of blocks (e.g., 2 blocks means each block is 5x5 for 10x10 matrix)

    % Check valid input
    if mod(d, num_blocks) ~= 0
        error('Total size d must be divisible by the number of blocks');
    end
    
    % Determine block size
    block_dim = d / num_blocks;
    
    % Initialize block diagonal matrix
    M = zeros(d);
    
    % Generate and place each block
    for i = 1:num_blocks
        % Generate random correlation matrix of size block_dim x block_dim
        A = randn(block_dim);
        P = A' * A;
        D = sqrt(diag(P));
        C = P ./ (D * D');
        
        % Symmetrize for numerical safety
        C = (C + C') / 2;
        
        % Place the block in the diagonal
        idx = (i-1)*block_dim + 1 : i*block_dim;
        M(idx, idx) = C;
    end
end