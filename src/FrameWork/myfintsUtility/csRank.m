function rankFts = csRank(fts, mode)
% FUNCTION: csRank
% DESCRIPTION: Find the rank acoss the fields
% INPUTS:
%	fts	- (myfints object) The object those field values are to be ranked.
%	mode - (string) Ranking mode:
%		'ascend' - Rank in ascending order (Smaller value -> lower rank)
%		'descand' - Rank in descending order (Greater value -> lower rank)
%	
% Rewritten on May 12, 2011 by Peter Liu since orignal not always fine.

if nargin < 2, mode = 'ascend'; end
rankFts = normalize(fts, 'mode', mode, 'method', 'rank');
