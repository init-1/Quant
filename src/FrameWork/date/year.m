function y = year(d, varargin) 
%YEAR Year of date. 
%   Y = YEAR(num_date)
%	Y = YEAR(str_date, str_fmt)

FTSASSERT(nargin == 1 || nargin == 2, 'Please enter D.'); 
if ~ischar(d)
    sd = size(d);
    d = d(:); 
end
y = datevec(datenum(d, varargin{:})); 
y = y(:,1);
if ~ischar(d)
    y = reshape(y,sd); 
end
end

