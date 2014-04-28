function [qtrtn, qtweight] = csqtrtn(signalfts, returnfts, varargin)
%% csqtrtn
%  Calculate quantile returns based on given signal.
%
% *INPUTS*
%
%   |signalfts| - (myfints object) time series of signal values
%   |reutrnfts| - (myfints object) time series on which quantile
%                  spreads are calculated
%   |'_option name_', _option value_, ...  -  optional arguments controling
%                  how the portfolio be constructed
%
% *list of options:*
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
%   * |qtile|, default is [0,0.2,0.4,0.6,0.8,1] (quintile return)
%   * |level|, a *number* among [1,2,3,4], default is 1, standing for the
%   GICS level 
%
% *Outputs* 
%
%   |qtrtn| - (myfints object)  time series of quantile
%   returns
%   |qtweight| - (cell array of myfints object)  time series of quintile portfolio weight
%
% The quantile spreads are calculated as weighted average of part of
%   |returnfts| greater than |long| quantile, minus weighted average of
%   part of |returnfts| less than |short| quantile. Clearly, by
%   _default_, it's quintile spread.
%

option.weight = [];
option.univ   = [];
option.GICS   = [];
option.qtile = [0,0.2,0.4,0.6,0.8,1];
option.level = 1;

option = Option.vararginOption(option, {'weight', 'univ', 'GICS', 'qtile', 'level'}, varargin{:});

% Check if input data are aligned
FTSASSERT(isaligneddata(signalfts, returnfts), 'signalfts and returnfts are not aligned');
for ftsField = {'weight', 'univ'}
    ftsname = ftsField{:};
    if isa(option.(ftsname), 'myfints')
       FTSASSERT(isaligneddata(signalfts, option.(ftsname)), '%s and signalfts are not aligned', ftsname);
       option.(ftsname) = fts2mat(option.(ftsname));
    end
end

% modified by Louis on 10 May 2012, use availability of signal instead of return to decide if weight should be 0
% nanRetIdx = isnan(fts2mat(returnfts));
nanRetIdx = isnan(fts2mat(signalfts));

if isempty(option.weight)
    option.weight = double(~nanRetIdx);
else
    option.weight(nanRetIdx) = 0; % we don't put weights on nonexistent stocks
end

if ~isempty(option.univ)
    option.weight(isnan(option.univ)) = 0;
end

s.type = '()'; s.subs = {option.weight == 0 | isnan(option.weight)};
signalfts = subsasgn(signalfts, s, NaN);
qtweight = cell(1,numel(option.qtile)-1);

for i = 1:numel(option.qtile)-1
    long = neutralize(signalfts, option.GICS...
        , @(x) bsxfun(@ge,x,quantile(x,option.qtile(i), 2)) & bsxfun(@le,x,quantile(x,option.qtile(i+1), 2))...
        , option.level);
    long = long .* option.weight;
    long  = bsxfun(@rdivide, long, nansum(long,2));   % renormalize
    QS = cssum(long .* returnfts);
%     MS = ftsmovsum(QS, option.window);
    field = ['Q',num2str(i)];
    if i == 1
        qtrtn = myfints(signalfts.dates,fts2mat(QS),field);
%         cumrtn = myfints(signalfts.dates,fts2mat(MS),field);
    else
        qtrtn = [qtrtn, myfints(signalfts.dates,fts2mat(QS),field)]; %#ok<AGROW>
%         cumrtn = [cumrtn, myfints(signalfts.dates,fts2mat(MS),field)];
    end
    qtweight{i} = long; 
end

return


