function resultCF = CashFlowDecomp(CF, FQTR)
% FUNCTION: CashFlowDecomp
% DESCRIPTION: Decompose the rolling cumulative cash flow items to quarterly cash flow
% INPUTS:
%	CF - A myfints object, cash flow items directly retrieved from
%	compustat (has to be in quarterly or monthly freq)
%	FQTR - A myfints object, NO. of financial quarters for each stock (has to be in quarterly or monthly freq)
%
% OUTPUT:
%	resultCF - The decomposed cash flow
%	
% Author: Louis Luo 
% Last Revision Date: 2011-04-05
% Vertified by: 

assert(CF.freq == 3 || CF.freq == 4, 'invalid freqency of CF - has be to 3 (Monthly) or 4(Quarterly)');
assert(isaligneddata(CF, FQTR), 'CF and FQTR has be to aligned for both field and dates');
% % Default integer for each freqency defined in matlab fints class
% % 1, DAILY, Daily, daily, D, d
% % 
% % 2, WEEKLY, Weekly, weekly, W, w
% % 
% % 3, MONTHLY, Monthly, monthly, M, m
% % 
% % 4, QUARTERLY, Quarterly, quarterly, Q, q
% % 
% % 5, SEMIANNUAL, Semiannual, semiannual, S, s
% % 
% % 6, ANNUAL, Annual, annual, A, a 

switch CF.freq
    case 3
        nLag = 3;
    case 4
        nLag = 1;
end
	
% [CF, FQTR] = aligndata(CF, FQTR);
LagCF = lagts(CF,nLag);

resultCF = CF - LagCF;
resultCF = resultCF(nLag+1:end);
CF = CF(nLag+1:end);
FQTR = FQTR(nLag+1:end);

%% implement resultCF(FQTR == 1) = CF(FQTR == 1)
[resultCF, CF, FQTR] = aligndata(resultCF, CF, FQTR);
resultCF(fts2mat(FQTR) == 1) = CF(fts2mat(FQTR) == 1);
