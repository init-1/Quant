function FXTS = LoadFXTS(fromCur, toCur, startDate, endDate, targetFreq)
% FUNCTION: LoadFXTS
%  FXTS = LoadFXTS(fromCur, toCur, startDate, endDate, targetFreq)
% DESCRIPTION: Load the FX rate time series from dataqa and pack it as a 'myfints' object.
% INPUTS:
%	FromCur     - (string) iso currency id of the currency used to quote
%	ToCur		- (string) iso currency id of the currency to be quoted
%	startDate	- (string) Start time
%	endDate		- (string) End time
%   targetFreq  - (optional) the target freqency of the retrieved financial time series, can be: 
%           1, DAILY, Daily, daily, D, d
%			2, WEEKLY, Weekly, weekly, W, w
%			3, MONTHLY, Monthly, monthly, M, m
%			4, QUARTERLY, Quarterly, quarterly, Q, q
%			5, SEMIANNUAL, Semiannual, semiannual, S, s
%			6, ANNUAL, Annual, annual, A, a 
% OUTPUT:
%	FXTS		- The FX rate time series
%	
% Author: Louis Luo 
% Last Revision Date: 2011-04-15
% Vertified by: 

%% Dealing with inputs
if nargin < 5
    targetFreq = 'NULL';
else
    targetFreq = targetFreq(1);
end

%% Executing store proc to retrieve data
sqlRet = runSP('dataqa','api.usp_GetFX',{'D002610002',fromCur,toCur,startDate,endDate});
if isempty(sqlRet)
    warning(['No Data in DB for the query']);
    FXTS = [];
    return;
end

%% Re-structure the data in the desired format
vecDate = sqlRet.date;
vecData = sqlRet.fxrate;

FXTS = myfints(datenum(vecDate),vecData,'rate');

if ~strcmpi(targetFreq, 'NULL')
    FXTS = aligndates(FXTS, targetFreq);
end

%save(filename,'fts');

return