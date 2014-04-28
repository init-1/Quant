function quantId = FieldId2QuantId(fieldId)
% FUNCTION: QuantId2FieldId
% DESCRIPTION: Convert the valid field Name in matlab to the quantstaging secid 
% INPUTS:
%   fieldId      - A cell array of strings
% OUTPUT:
%	quantId      - A cell array of security id as defined in quantstaging.dbo.secmstr	
%	
% Author: Louis Luo 
% Last Revision Date: 2011-03-30
% Vertified by: 

% assert(iscell(fieldId),'The input fieldId has to be a cell array');

% fieldId = reshape(fieldId,[1,numel(fieldId)]);

% fieldIdList = cell2mat( cellfun(@(c) {[',', c]}, fieldId));
% fieldIdList = fieldIdList(2:end);

% idMapping = runSP('QuantStrategy','fac.SecIdMapping',{fieldIdList});

% quantId = idMapping.secid;

% if ~iscell(quantId), quantId = {quantId}; end

% NaNcheck = cellfun(@(s) {isnan(s(1))}, quantId);
% if any(cell2mat(NaNcheck))
    % disp(['warning: some stocks cannot find matching secid in quantstaging']);
% end

quantId = fieldId;
