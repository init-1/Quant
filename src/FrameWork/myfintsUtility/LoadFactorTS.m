function fts = LoadFactorTS(secIds, factorId, startDate, endDate, isLive, varargin)
% FUNCTION: LoadFactorTS
%     factorTS = LoadFactorTS(secIds, factorId, startDate, endDate, IsLive, targetFreq, datebasis)
% DESCRIPTION: Load the specified factor time series for all securities in SecIds
%	pack the it as a 'myfints' object.
% INPUTS:
%	secIds      - A cell array of security id as defined in quantstaging.dbo.secmstr
%	factorId	- The Id of the factor defined in quantstrategy.fac.factormstr
%	startDate	- (string) Start time
%	endDate		- (string) End time
%   IsLive      - (int) 1: the factor value generated by live code, 0: the
%   factorvalue generated by backtest code
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
%	factorTS	- The factor myfints object
%

% varargin may be
%   targetFreq                       
% or
%   targetFreq, isOnTheFly, dateBasis
%
fts = DB.loadFactorTS(secIds, factorId, startDate, endDate, isLive, varargin{:});
end