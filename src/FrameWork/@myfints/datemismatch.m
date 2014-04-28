function [ovecDateA, ovecDateB]= datemismatch(iftsA, iftsB)
%myfints/datemimatch returns the vectors of uncommon dates in two inputed
%myfints objects: iftsA and iftsB

if nargin ~= 2
    error('incorrect number of input arguments');
end

if ~isa(iftsA, 'myfints') | ~isa(iftsB, 'myfints')
    error('both inputs should be myfints object');
end

vecDateA=getfield(iftsA, 'dates');
vecDateB=getfield(iftsB, 'dates');

vecIdxDateA=~ismember(vecDateA, vecDateB);
vecIdxDateB=~ismember(vecDateB, vecDateA);

ovecDateA=vecDateA(vecIdxDateA);
ovecDateB=vecDateB(vecIdxDateB);
