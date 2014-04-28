function result = LatestDataDate(ifts)
% FUNCTION: LatestDataDate
% DESCRIPTION: return the latest no-data-missing date for each field in the
% myfints object
% INPUTS:
%	ifts - a myfints object
% OUTPUT:
%   result a structure containing two fields:
%   result.field - a cell array of the data field names of ifts
%	result.latestDate - a cell array of corresponding date string which are the latest 
%   no-data-missing date for each field.
% Author: Louis Luo 
% Last Revision Date: 2011-04-07
% Vertified by: 

result.field = fieldnames(ifts,1); 
result.latestDate = cell(numel(result.field),1);
for i = 1:numel(result.field)
    idx = find(~isnan(fts2mat(ifts.(result.field{i}))),1,'last');
    if ~isempty(idx)
        result.latestDate{i} = datestr(ifts.dates(idx),'yyyy-mm-dd');
    else
        result.latestDate{i} = 'NULL';
    end
end