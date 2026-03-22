function d = amari_distance(P)

p = size(P,1);
A = abs(P);

rowMax = max(A,[],2); rowMax(rowMax==0)=eps;
colMax = max(A,[],1); colMax(colMax==0)=eps;

r = sum(A./rowMax,2)-1;
c = sum(A./colMax,1)-1;

d = (sum(r)+sum(c))/(2*p*(p-1));

end