function [ovecFieldA, ovecFieldB]= fieldmismatch(iftsA, iftsB)
%myfints/datemimatch returns the vectors of uncommon dates in two inputed
%myfints objects: iftsA and iftsB

if nargin ~= 2
    error('incorrect number of input arguments');
end

if ~isa(iftsA, 'myfints') | ~isa(iftsB, 'myfints')
    error('both inputs should be myfints object');
end

vecFieldA=fieldnames(iftsA);
vecFieldB=fieldnames(iftsB);

vecIdxFieldA=~ismember(vecFieldA, vecFieldB);
vecIdxFieldB=~ismember(vecFieldB, vecFieldA);

ovecFieldA=vecFieldA(vecIdxFieldA);
ovecFieldB=vecFieldB(vecIdxFieldB);

end % of function
