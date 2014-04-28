function result = meanif(fts, dim, cond)
% FUNCTION: meanif(fts, dim, condition)
% DESCRIPTION: Calculate conditional mean along a particular direction
% INPUTS:
%	fts		- The 'myfints' object those condition mean are calculated.
%	dim		- Direction on which mean is calculated. 
%		1: mean values across different time
%		2: mean values across different field
%	cond	- (myfints object or matrix) The conditions
%
% OUTPUT:
%	result - The conditional mean
%
% Author: louis Luo 
% Last Revision Date: 2010-11-23
% Vertified by: 
%

result = funif(fts, dim, cond, @nanmean, 'mean');

