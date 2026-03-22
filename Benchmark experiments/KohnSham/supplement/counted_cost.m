function f = counted_cost(Q, Hred, counter)
%COUNTED_COST  objective with evaluation counting (script-safe)
% counter is a handle object with field .n (see Counter class below)
counter.n = counter.n + 1;
f = trace(Q' * Hred * Q);
end