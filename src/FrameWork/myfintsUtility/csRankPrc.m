function rankFts = csRankPrc(fts, mode)
% FUNCTION: csRankPrc
% DESCRIPTION: Find the percentile acorss the fields
% INPUTS:
%	fts	- (myfints object) The object those field values are to be ranked.
%	mode - (string) Ranking mode:
%		'ascend' - Rank in ascending order (Smaller value -> lower rank)
%		'descand' - Rank in descending order (Greater value -> lower rank)
%	
%	price	- (myfints object) Price of securities
%	horizon	- (numeric) Return horizon, in time step
%
% OUTPUT:
%	rank - (myfints object) The time series of percentile of each field, values always lies between 0 and 1. 
%		NaN value will always have NaN rank.
%
% FIXME: Same value across a row may have a different rank. Make them the same rank if the values are the same.
%
% Author: Clarence Yuen 
% Last Revision Date: 2010-11-10
% Vertified by: 
%
% Similar as matlab's quantile. Not recommend using this function.

% warning('MYFINTS:OBSOLETED', 'Using csRanPrc is not recommended.');

if nargin < 2, mode = 'ascend'; end
f = @(x) mycsrank(x, mode);
rankFts = uniftsfun(fts, f);
end

function rnk = mycsrank(data, mode)
invalid = isnan(data);
nfield = size(data, 2);

[~, rnk] = sort(data, 2);
[~, rnk] = sort(rnk, 2);
rnk(invalid) = nan;

validCnt = sum(not(invalid), 2);
switch(lower(mode))
case 'ascend'
	rnk = 100 * (rnk - 0.5) ./ repmat(validCnt, [1, nfield]);
case 'descend'
	rnk = 100 * (1 - (rnk - 0.5) ./ repmat(validCnt, [1, nfield]));
otherwise
	error('Unknown ranking mode ''%s''', mode);
end
end
