function d = eomdate(varargin) 
%EOMDATE Last date of month. 
% Syntax:
%    d = eomdate(date)
%    d = emodate(y, m)

if nargin == 1
    [y,m,~,~,~,~] = datevec(varargin{1});
elseif nargin == 2
    [y, m] = varargin{:};
else
    FTSASSERT(false, 'too many arguments');
end

ld = eomday(y,m);
d = datenum(y,m,ld);
end

