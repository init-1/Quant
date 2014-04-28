function newFts = orderField(oldFts, fieldList)
% FUNCTION: orderField
% DESCRIPTION: Arrange the field according to user specified field list. Fields that are not in 
%	user specified field list will be discard. Non existing fields will be ignored.
% INPUTS:
%	oldFts		- (myfints object) The object those fields are to be ordered.
%	fieldList	- (cell array) User specified field list.
%
% OUTPUT:
%	newFts - (myfints object) The time series of percentile of each field, values always lies between 0 and 1. 
%
newFts = oldFts(:, fieldList);
end
