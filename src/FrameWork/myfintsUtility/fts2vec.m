% this function convert the myfints object to 3 vectors: date, secid, value
% input: ifts - the input myfints
%        deleteNaN - 1 or 0: 1, all the NaN records will be deleted from
%        the result, 0: NaN will be kept.
% 


function [Dates_Col, quantId_Col, Data_Col] = fts2vec(ifts, deleteNaN)

matlabId = fieldnames(ifts,1);
quantId = FieldId2QuantId(matlabId);
Data = fts2mat(ifts);
Dates = cellstr(datestr(ifts.dates,'yyyy-mm-dd'));

[NDate, NSec] = size(Data);
% Align data
Data_Col = reshape(Data,[numel(Data),1]);

% Align dates
Dates_Col = repmat(Dates,[NSec,1]);

% Align secid
quantId = reshape(quantId,[1,numel(quantId)]);
quantId_Col = repmat(quantId, [NDate,1]);
quantId_Col = reshape(quantId_Col,[numel(quantId_Col),1]);

if deleteNaN == 1
    idx = isnan(Data_Col);
    Data_Col(idx) = [];
    Dates_Col(idx) = [];
    quantId_Col(idx) = [];
end

return