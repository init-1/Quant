function fts = ftsmovfun(fts, window, fun, fieldname)
% FUNCTION: ftsmovfun
% DESCRIPTION: Calculate the moving standard deviation of a time series, NaN will be
% ignored in calculation if ignoreNaN = 1
% INPUTS:
%	oldFts - (myfints object) 
%   window - if windows is inf, it's the expanding window
%
% OUTPUT:
%	newFts - The resulting myfints object
%
% Author: Louis Luo
% Last Revision Date: 2010-11-29
% Vertified by: 
%
if nargin < 4, fieldname = []; end
if ischar(fieldname), fieldname = {fieldname}; end
f = @(x) movfun(x, window, fun, length(fieldname));
fts = uniftsfun(fts, f, fieldname);
end

function newdata = movfun(olddata, window, fun, ncols)
% Expanding case can be represented by setting window = inf.
    if ncols == 0, ncols = size(olddata,2); end
    T = size(olddata,1);
    newdata = nan(T, ncols);
    if window >= 0
        for i = 1:T
            newdata(i,:) = fun(olddata(max(i-window+1,1):i,:));
        end
    else
        for i = 1:T
            newdata(i,:) = fun(olddata(i:min(i-window-1,T),:));
        end
    end
end
