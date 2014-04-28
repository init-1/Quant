function factorInfo = LoadFactorInfo(factorIds, colNames, isprod)
% FUNCTION: LoadFactorInfo
% DESCRIPTION: Load information of factors
% INPUTS:
%	factorIds - a cell array of factorIds
%	colNames  - (comma separaterd string or cell array) - The column names in quantstrategy.fac.FactorMstr 
%
% OUTPUT:
%	factorInfo	- A structure which contains the given column data
%	
% Author: Louis Luo
% Last Revision Date: 2011-04-04
% Vertified by: 

if nargin < 3
    isprod = 0;
end

if(~iscell(colNames)); colNames = {colNames}; end
queryCol = cell2mat( cellfun(@(c) {[', ', c]}, colNames) );
queryCol = queryCol(2:end);

if ~iscell(factorIds), factorIds = {factorIds}; end
factorstr = sprintf(',%s', factorIds{:});
if isprod == 1
    factorInfo = runSP('QuantStrategy','fac.GetFactorInfoProd',{factorstr, queryCol});    
else
    factorInfo = runSP('QuantStrategy','fac.GetFactorInfo',{factorstr, queryCol});
end