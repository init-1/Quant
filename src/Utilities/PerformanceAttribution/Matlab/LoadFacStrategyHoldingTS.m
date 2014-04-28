function [pffts, bmfts, actfts]=LoadFacStrategyHoldingTS(StrategyId, aggID, islive, dtStart, dtEnd, DBServer, varargin)
% FUNCTION: LoadStrategyHoldingTS
% DESCRIPTION: This function load the time series of specified item for all securities specified, then pick
%		the it as a 'myfints' object.
% INPUTS:
%   StrategyID  - The StrategyId of the strategy
%	aggID		- The aggID	of the index
%	dtStart		- (string) Start time
%	dtEnd		- (string) End time
%	DBServer	- (optional) The DB server name.
%	varagin		- (optional) Other optional parameters, including:
%		'Freq' - Frequency of data to convert to
%			1, DAILY, Daily, daily, D, d
%			2, WEEKLY, Weekly, weekly, W, w
%			3, MONTHLY, Monthly, monthly, M, m
%			4, QUARTERLY, Quarterly, quarterly, Q, q
%			5, SEMIANNUAL, Semiannual, semiannual, S, s
%			6, ANNUAL, Annual, annual, A, a 
%
% OUTPUT:
%	fts		- The item time series, encapsulated as an object of 'myfints'
%	
% Author: Clarence Yuen (Modified from Bing's LoadSecTS)
% Last Revision Date: 2010-11-09
% Vertified by: 
%


if islive == 0 % models that are not in production yet
    sqlRet = runSP('quantworkspace','rpw.usp_getActHoldingTS_BT',{StrategyId, dtStart, dtEnd, aggID}, '');
else
    sqlRet = runSP('quantworkspace','rpw.usp_getActHoldingTS',{StrategyId, dtStart, dtEnd, aggID}, '');
end

vecDate = sqlRet.date;
vecId = sqlRet.secid;
vecPFWeight = sqlRet.pfweight;
vecBMWeight = sqlRet.bmweight;
vecACTWeight = sqlRet.actweight;

stu1.Date	= [];
stu1.Id		= [];
stu1.Data	= [];
[stu1.Data, IX, stu1.Date, stu1.Id] = vec2mat(vecDate, vecId, vecPFWeight);

stu2.Date	= [];
stu2.Id		= [];
stu2.Data	= [];
[stu2.Data, IX, stu2.Date, stu2.Id] = vec2mat(vecDate, vecId, vecBMWeight);

stu3.Date	= [];
stu3.Id		= [];
stu3.Data	= [];
[stu3.Data, IX, stu3.Date, stu3.Id] = vec2mat(vecDate, vecId, vecACTWeight);

% vecId = strrep(stu1.Id, '.', '_');
% celId = strrep(vecId, '@', '_');
celId = QuantId2FieldId(stu1.Id);
pffts = myfints(stu1.Date,stu1.Data,celId);
bmfts = myfints(stu2.Date,stu2.Data,celId);
actfts = myfints(stu3.Date,stu3.Data,celId);

param = cell2struct(varargin(2:2:end), varargin(1:2:end-1), 2);
if(isfield(param, 'Freq'))
    dates = genDateSeries(dtStart, dtEnd, param.Freq, 'Busdays', 1);
    [pffts, bmfts, actfts] = aligndates(pffts, bmfts, actfts, dates);
    pffts = backfill(pffts, 26);
    bmfts = backfill(bmfts, 26);
    actfts = backfill(actfts, 26);
% 	pffts = convertto(pffts, param.Freq, 'BusDays', 1, 'CalcMethod', 'Exact'); % Have to be exact here
%     pffts = backfill(pffts, 26);
% 	pffts.dates(end) = endDate;
%     
%     endDate = datenum(dtEnd);
% 	bmfts = convertto(bmfts, param.Freq, 'BusDays', 1, 'CalcMethod', 'Exact'); % Have to be exact here
%     bmfts = backfill(bmfts, 26);
% 	bmfts.dates(end) = endDate;
%     
%     endDate = datenum(dtEnd);
% 	actfts = convertto(actfts, param.Freq, 'BusDays', 1, 'CalcMethod', 'Exact'); % Have to be exact here
%     actfts = backfill(actfts, 26);
% 	actfts.dates(end) = endDate;
end

%save(filename,'fts');

end % of file