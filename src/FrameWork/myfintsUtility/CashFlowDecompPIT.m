function resultCF = CashFlowDecompPIT(CF, FQTR)
% FUNCTION: CashFlowDecomp
% DESCRIPTION: Decompose the rolling cumulative cash flow items to quarterly cash flow
% INPUTS:
%	CF - a cell array of myfints object, which are the Compustat
%	Point-In-Time cash flow item directly retrieved from LoadRawItemPIT function
%   CF{i} is the ith-quarter-back cash flow value at each point in time
%	FQTR - a cell array of myfints object, which are the Compustat
%	Point-In-Time financial quarters for each stock
%
% OUTPUT:
%	resultCF - a cell array of myfints, which are the decomposed cash flow
%	
% Author: Louis Luo 
% Last Revision Date: 2011-04-05
% Vertified by: 

assert(numel(CF) == numel(FQTR), 'Error: the size of CF and FQTR does not match');

resultCF = cell(numel(CF)-1,1);

for i = 1:numel(CF)-1
    assert(isaligneddata(CF{i},CF{i+1}),'myfints in CF are not all aligned');
    assert(isaligneddata(CF{i},FQTR{i}), 'myfints in CF and FQTR are not all aligned');
    originalCF = CF{i};
    deCompCF = CF{i} - CF{i+1};
    deCompCF(fts2mat(FQTR{i})==1) = originalCF(fts2mat(FQTR{i})==1);
    resultCF{i} = deCompCF;
end
    
return