function fts2xls(fts, fname, sheetName)
    out = ['Date' fieldnames(fts,1)'...
         ; mat2cell(datestr(fts.dates,'yyyy-mm-dd'), ones(size(fts.dates)))...
         , num2cell(fts2mat(fts))];
     
     xlswrite(fname, out, sheetName);
end