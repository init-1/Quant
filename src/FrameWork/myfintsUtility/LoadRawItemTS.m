function itemTS = LoadRawItemTS(secIds, itemId, startDate, endDate, varargin)
% Syntax:
%    itemTS = LoadRawItemTS(secIds, itemId, startDate, endDate, targetFreq)
% DESCRIPTION: Load the specified item time series for all securities in SecIds
%	and pack it as a 'myfints' object.
% INPUTS:
%	secIds      - A cell array of security id as defined in quantstaging.dbo.secmstr
%	itemId		- The itemID of the item defined in dataqa..itemmstr
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
itemTS = DB.loadRawItemTS(secIds, itemId, startDate, endDate, varargin{:});
end

