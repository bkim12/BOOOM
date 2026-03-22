function r = kkt_residual(H, Q)
%KKT_RESIDUAL  r = || H Q - Q(Q' H Q) ||_F
HQ = H*Q;
QtHQ = Q' * HQ;
r = norm(HQ - Q*QtHQ, 'fro');
end