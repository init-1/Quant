function fieldId = QuantId2FieldId(quantId)
% FUNCTION: QuantId2FieldId
% DESCRIPTION: Convert the quantstaging secid to be valid field Name in matlab
% INPUTS:
%	quantId      - A cell array of security id as defined in quantstaging.dbo.secmstr
% OUTPUT:
%	fieldId      - A cell array of strings
%	
% Author: Louis Luo 
% Last Revision Date: 2011-03-30
% Vertified by: 

% assert(iscell(quantId),'Input should be a cell array of string');

% fieldId = strrep(quantId, '.', '_');
% fieldId = strrep(fieldId, '@', '_');
% fieldId = cellfun(@(s) {['_' s]},fieldId);

% if numel(unique(quantId)) ~= numel(unique(fieldId))
    % disp(['warning: the mapping results in duplicate field names!']);
% end

fieldId = quantId;
