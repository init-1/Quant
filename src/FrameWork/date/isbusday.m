function tf = isbusday(date, holiday, weekend)
% Syntax: tf = isbusday(date, holiday, weekend)
% date must be numeric
if nargin < 3, weekend = Freq.weekend; end
if nargin < 2, holiday = Freq.holidays; end

tf = Freq.isbusday(date, holiday, weekend);
end
