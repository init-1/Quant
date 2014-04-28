function [secIds, varargout] = LoadIndexHoldingTS(aggId, startDate, endDate, isLive, varargin)
% FUNCTION: LoadIndexHoldingTS
%   [secIds, varargout] = LoadIndexHoldingTS(aggId, startDate, endDate, isLive, targetFreq)
% DESCRIPTION: Load the index holding time series for all securities in SecIdList
%	pack it as a 'myfints' object.
% INPUTS:
%	aggId       - (string) The index id defined in quantstaging.dbo.aggmstr
%	startDate	- (string) Start Date
%	endDate		- (string) End Date
%   isLive      - (bit) indicate whether it is for retreiving the live
%   holding or historical holding 
%   targetFreq  - (string) the target freqency of the retrieved financial
%   time series, can be: 
%           1, DAILY, Daily, daily, D, d
%			2, WEEKLY, Weekly, weekly, W, w
%			3, MONTHLY, Monthly, monthly, M, m
%			4, QUARTERLY, Quarterly, quarterly, Q, q
%			5, SEMIANNUAL, Semiannual, semiannual, S, s
%			6, ANNUAL, Annual, annual, A, a 
%
% OUTPUT:
%   secIds      - The list of distinct secid, as defined in quantstaging.dbo.secmstr
%	varargout	- The holding time series, encapsulated as an object of 'myfints'
%	
   if ischar(aggId), aggId = {aggId}; end
   
    if isLive == 1
        varargin = {};  % frequency meaningless in this case
        startDate = endDate;
    end

    FTSASSERT(aggId{1}(1) ~= 'X', 'aggId is invalid, please pass in the Id defined in quantstaging.dbo.aggmstr');

    ret = [];
    varargout = cell(size(aggId));
    for i = 1:numel(aggId)
        varargout{i} = DB.load(@fun, aggId, '', varargin{:});
    end

    secIds = unique(ret.SecId);

    function r = fun(aggIdList, freq)
        if isempty(ret)
            db = DB('QuantStrategy');
            ret = db.runSql('fac.GetHoldingTS',aggIdList,startDate,endDate,freq);
        end
        idx = ismember(ret.AggId, aggId(i));
        r.DataDate = ret.DataDate(idx);
        r.SecId    = ret.SecId(idx);
        r.TargetVal= ret.TargetVal(idx);
    end
end
