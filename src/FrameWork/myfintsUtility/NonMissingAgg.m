function varargout = NonMissingAgg(fun, mode, num, varargin)
% FUNCTION: NonMissingAgg
% DESCRIPTION: apply aggregate functions (e.g. mean, sum, std, specified by fun) 
% to first/last n non-nan observations in each field of a series of myfints object 
%
% INPUTS:
%     fun: (function handle) for the aggregation function - @sum, @mean...
%     mode: (string) - 'first' or 'last'
%     num: (int) - number of non-missing observations the function applies to
%     varargin: - a series of input myfints
% OUTPUT:
%     varargout: - a series of aggregate myfints with one date, if mode = 'first', the
%     date is the first date of each myfints, if mode = 'last', the date is
%     the last date of each myfints
%
% Author: louis.luo
% Last Revision Date: 12-Apr-2011
% Vertified by: 
%

FTSASSERT(isa(@sum, 'function_handle'), 'fun must be a function handle!');
FTSASSERT(strcmpi(mode,'first') || strcmpi(mode, 'last'), 'invalid mode: mode can only be first or last'); 

varargout = cell(size(varargin));

for j = 1:numel(varargin)
    ifts = varargin{j};
    [~,c] = size(ifts);
    rawData = fts2mat(ifts);
    aggData = nan(1,c);
    for i = 1:c
        fieldData = rawData(:,i);
        idx = find(~isnan(fieldData),num,mode);
        if ~isempty(idx)
            aggData(i) = fun(fieldData(idx));
        end
    end
    if strcmpi(mode, 'first')
        aggDate = ifts.dates(1);
    else
        aggDate = ifts.dates(end);
    end
    varargout{j} = myfints(aggDate,aggData,fieldnames(ifts,1));
end