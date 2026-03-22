function G = ajd_egrad(C, W)

[p,~,m] = size(C);
G = zeros(p,p);

for k = 1:m
    M = W' * C(:,:,k) * W;
    Off = M - diag(diag(M));
    G = G + 4 * C(:,:,k) * W * Off;
end

end