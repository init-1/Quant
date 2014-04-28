function ofts = csgroupfun(fun, ifts, group)
% FUNCTION: csgroupfun(fun, fts, group)
% DESCRIPTION: apply an crosssectional aggregate function to a myfints object according to
% certain grouping rule, and output the aggregated value in a myfints
% object.
%
% INPUTS:
%   fun     - a function handle specifying the type of functions to apply
%	ifts    - myfints object to which the group function is applied.
%	group	- myfints object which contains the group information, must
%	have the same dates and fields as ifts
%
% OUTPUT:
%	ofts    - the output myfints which has the same dates and fields as
%	ifts, but value replaced by the calculated group mean
%
% Author: louis Luo 
% Last Revision Date: 2011-05-02
% Vertified by: 
%

FTSASSERT(isa(fun,'function_handle'),'input fun has to be a function handle');
ofts = biftsfun(ifts, group, @(l,r) groupMat(l,r,fun));
end

function res = groupMat(iftsData, groupData, fun)
    [r, c] = size(iftsData);
    res = nan(r,c);
    for i = 1:r
        uniGroup = unique(groupData(i,~isnan(groupData(i,:))));
        nGroup = numel(uniGroup);
        for j = 1:nGroup
            res(i,groupData(i,:) == uniGroup(j)) = fun(iftsData(i,groupData(i,:) == uniGroup(j))');
        end
    end
end