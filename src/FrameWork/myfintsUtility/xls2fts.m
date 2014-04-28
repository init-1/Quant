function varargout = xls2fts(fname, sheetName, dateCol, sidCol, valCols)
% Call like
%   [a,b] = xls2fts('c:\gcc.xlsx', 'sheet1', ...
%         'B2:B21825', 'G2:G21825', {'P2:P21825', 'O2:O21825'});
% The last cell vector of string indicates value columns to be used
% as values in returned myfints; each one corresponds to a myfints obj.
% In the example above, since two columns provided as values, so
% two myfints (i.e., a and b) are going to be returned.

if ischar(valCols), valCols = {valCols}; end

if fname(1) ~= '\' && fname(1) ~= '/'
    fname = [pwd '/' fname];
end

exl = actxserver('excel.application');
exlFile = exl.Workbooks.Open(fname);
sheet = exlFile.Sheets.Item(sheetName);

date = sheet.Range(dateCol).Value;
sid  = sheet.Range(sidCol).Value;

date = datenum(date);

nFts = length(valCols);
varargout = cell(1,nFts);
for i = 1:nFts
    val = sheet.Range(valCols{i}).Value;
    val(~cellfun(@isnumeric, val)) = {NaN};
    val = cell2mat(val);
    varargout(i) = mat2fts(date, val, QuantId2FieldId(sid));
    varargout{i}.desc = valCols{i};
end

exl.Workbooks.Close;
exl.Quit;
exl.delete;
end
