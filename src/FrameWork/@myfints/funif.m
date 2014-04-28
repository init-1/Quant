function result = funif(fts, dim, cond, fhandle, fieldname)
% FUNCTION: funif(fts, dim, condition)
% DESCRIPTION: Calculate conditional mean along a particular direction
% INPUTS:
%	fts		- The 'myfints' object those condition mean are calculated.
%	dim		- Direction on which mean is calculated. 
%		1: mean values across different time
%		2: mean values across different field
%	cond	- (myfints object or matrix) The conditions
%
% OUTPUT:
%	result - The returned myfint result
%
% Author: louis Luo 
% Last Revision Date: 2010-11-23
% Vertified by: 
%

% LIMITATION: only nan* group functions are allowed currently.

f = @(fts_,cond_) fun(fts_, dim, cond_, fhandle);
result = biftsfun(fts, cond, f, fieldname);
end

function res = fun(data, dim, cond, fhandle)
% Perform something spefied by fhandle on elements of data specified by cond 
% along dim dimension.
    data(not(cond)) = nan;
    res = fhandle(data, dim);
end