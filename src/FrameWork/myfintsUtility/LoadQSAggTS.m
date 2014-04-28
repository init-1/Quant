function itemTS = LoadQSAggTS(aggIds, itemId, startDate, endDate, varargin)
% FUNCTION: LoadIndexItemTS
%   itemTS = LoadQSAggTS(aggIds, itemId, startDate, endDate, targetFreq)
% DESCRIPTION: Load the specified item time series for all securities in aggIds
%	and pack it as a 'myfints' object.
% INPUTS:
%	aggIds      - A cell array of index id as defined in quantstaging.dbo.aggmstr
%	itemId		- The itemID of the item defined in quantstaging.dbo.itemmstr
%	startDate	- (string) Start time
%	endDate		- (string) End time
%   targetFreq  - (optional) the target freqency of the retrieved financial time series, can be: 
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
itemTS = DB.load(@db_fun, aggIds, '', varargin{:});

function ret = db_fun(aggIdList, targetFreq)
    db = DB('QuantStrategy');
    ret = db.runSql('fac.GetAggTS',itemId,aggIdList,startDate,endDate,targetFreq);
    ret.SecId = ret.AggId;
end
end

