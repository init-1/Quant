function oblnSame = isidenticalfields(iftsA, iftsB)
%myfints/isidenticalFields checks if the Field series of two input objects
%are the same

[vecFieldA, vecFieldB]= fieldmismatch(iftsA, iftsB);

oblnSame=false;
if isempty(vecFieldA) && isempty(vecFieldB)
    oblnSame=true;
end
