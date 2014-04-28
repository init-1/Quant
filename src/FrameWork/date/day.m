function y = day(d, varargin) 
%DAY Year of date. 
%   d = YEAR(num_date)
%	d = YEAR(str_date, str_fmt)

FTSASSERT(nargin == 1 || nargin == 2, 'Please enter D.');
if ~ischar(d)
    sd = size(d);
    d = d(:); 
end
y = datevec(datenum(d, varargin{:})); 
y = y(:,3);
if ~ischar(d)
    y = reshape(y,sd); 
end
end

