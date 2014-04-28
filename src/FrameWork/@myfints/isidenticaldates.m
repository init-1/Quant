function oblnSame = isidenticaldates(iftsA, iftsB)
%myfints/isidenticaldates checks if the date series of two input objects
%are the same

[vecDateA, vecDateB]= datemismatch(iftsA, iftsB);

oblnSame=false;
if isempty(vecDateA) && isempty(vecDateB)
    oblnSame=true;
end
