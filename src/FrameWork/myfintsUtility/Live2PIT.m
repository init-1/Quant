function ftsArray = Live2PIT(ifts, nPeriod)
% FUNCTION: Live2PIT
% DESCRIPTION: Convert the live fundamental data to Point-In-Time format
% INPUTS:
%	 ifts      - a myfints which contains raw fundamental data (have not been backfilled)
%    nPeriod   - (int) number of periods data to convert to PIT 
%
% OUTPUT:
%	 ftsArray  - an array of myfints, each myfints only has one date: the latest date in ifts, and 
%    the ith myfints in this array is the ith period looking back from that date.
%	
% Author: Louis Luo 
% Last Revision Date: 2011-03-08
% Vertified by: 

assert(isa(ifts,'myfints'),'input ifts has to be a myfints')
assert(nPeriod > 0, 'input nPeriod has to be a positive int');

fields = fieldnames(ifts,1);
endDate = ifts.dates(end);
rawData = fts2mat(ifts);
[r,c] = size(rawData);
newData = nan(r,c);
ftsArray = cell(1,nPeriod);

for j = 1:c
    idx = ~isnan(rawData(:,j));
    if ~isempty(idx)
        nValue = sum(idx);
        newData(end-nValue+1:end,j) = rawData(idx,j);
    end
end

for i = 1:nPeriod
    ftsArray{i} = myfints(endDate, newData(end-i+1,:), fields, [], ['Period ',num2str(i)]);
end
