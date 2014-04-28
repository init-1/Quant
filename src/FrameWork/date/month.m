function [n, m] = month(d, varargin) 
%MONTH Year of date. 
%   Y = YEAR(num_date)
%	Y = YEAR(str_date, str_fmt)

FTSASSERT(nargin == 1 || nargin == 2, 'Please enter D.'); 
if ~ischar(d)
    sd = size(d);
    d = d(:); 
end
n = datevec(datenum(d, varargin{:})); 
n = n(:,2);

mths = ['NaN';'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul'; ...
    'Aug';'Sep';'Oct';'Nov';'Dec'];
idx = n + (n == 0); %(n == 0) handles the case when d = 0
idx(isnan(idx)) = 0;
m = mths(idx+1,:);

if ~ischar(d)
    n = reshape(n,sd); 
end
end

