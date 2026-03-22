function M = create_toeplitz_PSD(d)
    % toeplitz
    % create k many First order autoregressive AR(1) PSD (dxd) 
    M = zeros(d);
    p = unifrnd(0.1,0.9);

    [i,j] = meshgrid(1:d,1:d);
    M(i > j) = p.^(i(i > j) - j(i > j));  % Set M(i,j) = p^(i-j) for upper triangle
    M = M + M'+eye(d); 
end
    
    
