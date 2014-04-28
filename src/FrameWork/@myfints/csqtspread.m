function [ofts, weight] = csqtspread(signalfts, returnfts, varargin)
%% csqtspread
%  Calculate quantile spreads based on given signal.
%
% *INPUTS*
%
%   |signalfts| - (myfints object) time series of signal values
%   |reutrnfts| - (myfints object) time series on which quantile
%                  spreads are calculated
%   |'_option name_', _option value_, ...  -  optional arguments controling
%                  how the portfolio be constructed
%
% *Outputs*
%
%   |ofts| - (myfints object)  time series of quantile spreads and its moving sum
%   |weight| - (myfints object) time series of weight associated with
%   |returnfts|
%
% *list of options:*
%
%   * |window|, *integer*, indicates the window size when calculating
%               moveing sums, _default_ |inf|
%   * |weight|, a *myfints* object compatible to |returnfts|,
%               indicates the weights for corresponding elements in |returnfts|,
%              _default_ equal weight
%   * |univ|, a *myfints* object compatible to [returnfts], indicating
%               whether the stock is in the universe at each time point.
%               if this option is specified, the quintile spread will be
%               only calculated for stocks within the universe at each point in time.
%   * |GICS|, a *myfints* onject compatible to |returnfts|,
%             contains GICS code corresponding to elements in |returnfts|. If
%             provided, the quantile spreads are calculated on each sector divided by GICS;
%             if _omitted_, the quantile spreads are calculated on the whole universe
%             (|returnfts|)
%   * |level|, a *number* in [1,2,3,4], default to be 1, standing for the
%   level of gics sectors (1 for sector, 2 for industry group, 3 for industry ,4 for subindustry 
%   * |long|, a *number* between [0,1], default is 0.8
%   * |short|, a *number* between [0,1], default is 0.2
%
% The quantile spreads are calculated as weighted average of part of
%   |returnfts| greater than |long| quantile, minus weighted average of
%   part of |returnfts| less than |short| quantile. Clearly, by
%   _default_, it's quintile spread.
%
%%
option.window = inf;
option.long   = 0.8;  % >
option.short  = 0.2;  % <

if nargin == 3
    option.window = varargin{:};  % for forward (previous) compability
else
    s = warning('query' ,'VAROPTION:UNRECOG');
    warning('off', 'VAROPTION:UNRECOG');
    option = Option.vararginOption(option, {'window', 'long', 'short'}, varargin{:});
    warning(s.state, 'VAROPTION:UNRECOG');
end

FTSASSERT(option.long > option.short);

option.varargin = [option.varargin 'qtile', [0 option.short option.long 1]];
[qtrtn, qtweight] = csqtrtn(signalfts, returnfts, option.varargin{:});
weight = qtweight{3} - qtweight{1};
qtrtn = fts2mat(qtrtn);
QS = qtrtn(:,3) - qtrtn(:,1);
ofts = myfints(signalfts.dates,[QS cumsum(QS)],{'mean','MS'});
weight.desc = 'Long-Short Portfolio Weights';
end


