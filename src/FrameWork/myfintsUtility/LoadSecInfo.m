function secInfo = LoadSecInfo(Id, colNames, startDate, endDate, isIndex)
% FUNCTION: LoadSecInfo
% DESCRIPTION: Load information of all securities involved in specified index for given time period
% INPUTS:
%	Id	  - The Id of the index
%	colNames  - (comma separaterd string or cell array) - The column names in quantstaging.dbo.secmstr to be extracted
%	startDate - (string) Start time
%	endDate	  - (string) End time
%   isIndex   - (logic) <optional> - 1 stands for Id is an aggid (default), 0 stands for Id is a cell array of secid 

%
% OUTPUT:
%	secInfo	- A structure which contains the given column data
%	
% Author: Louis Luo
% Last Revision Date: 2010-11-09
% Vertified by: 
%

if nargin < 5
    isIndex = 1;
end

if(~iscell(colNames)); colNames = {colNames}; end
queryCol = cell2mat(cellfun(@(c) {[', ', c]}, colNames) );
queryCol = queryCol(2:end);

if isIndex == 1
    aggId = Id;
    secInfo = runSP('QuantStrategy', 'fac.GetSecInfo', {aggId, queryCol, startDate, endDate});
else
    if iscell(Id)
        secIdList = sprintf('%s,', Id{:});
        secIdList = secIdList(1:end-1);
    end
    secInfo = runSP('QuantStrategy',  'fac.GetSecInfoByStock', {secIdList, queryCol});
    F = fieldnames(secInfo);
    for i = 1:numel(F), 
        if ischar(secInfo.(F{i})), secInfo.(F{i}) = {secInfo.(F{i})}; end
    end 
end

if isIndex == 0
    [idx, loc] = ismember(Id, secInfo.SecId);
    secInfo.SecId = Id;
    F = fieldnames(secInfo);
    F(ismember(F,('SecId'))) = [];
    for i = 1:numel(F)
        origfield = secInfo.(F{i});
        if iscell(origfield)
            tempfield = cell(numel(Id),1); 
            tempfield(idx) = origfield(loc(idx));
            % replace any missing value with empty string: ''
            tempfield(~idx) = {''};
            for j = 1:numel(tempfield)
                if isnan(tempfield{j})
                    tempfield(j) = {''};
                end
            end
        else
            tempfield = nan(numel(Id),1);
            tempfield(idx) = origfield(loc(idx));
            tempfield(~idx) = NaN;
        end
        secInfo.(F{i}) = tempfield;
    end
end
