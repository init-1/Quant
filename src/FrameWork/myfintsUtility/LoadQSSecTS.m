function itemTS = LoadQSSecTS(secIds, itemId, seq, startDate, endDate, varargin)
% FUNCTION: LoadQSSecTS
%  itemTS = LoadQSSecTS(secIds, itemId, seq, startDate, endDate, targetFreq)
% DESCRIPTION: Load the specified item time series from quantstaging.dbo.secTS table for all securities in SecIds
%	and pack it as a 'myfints' object.
% INPUTS:
%	secIds      - A cell array of security id as defined in quantstaging.dbo.secmstr
%	itemId		- The itemID of the item defined in quanstaging.dbo.itemmstr
%   seq         - The seq of the item (0 for raw) as defined in quantstaging.dbo.seqinfo
%	startDate	- (string) Start time
%	endDate		- (string) End time
%   targetFreq  - (optional) the target freqency of the retrieved financial
%   time series, can be: 
%           1, DAILY, Daily, daily, D, d
%			2, WEEKLY, Weekly, weekly, W, w
%			3, MONTHLY, Monthly, monthly, M, m
%			4, QUARTERLY, Quarterly, quarterly, Q, q
%			5, SEMIANNUAL, Semiannual, semiannual, S, s
%			6, ANNUAL, Annual, annual, A, a 
%
% OUTPUT:
%	itemTS		- The item time series
%	
db = DB('QuantStrategy');
db_fun = @(secIdList, targetFreq) db.runSql('fac.GetSecTS',itemId,seq,secIdList,startDate,endDate,targetFreq);
itemTS = DB.load(db_fun, secIds, secIds, varargin{:});
end
