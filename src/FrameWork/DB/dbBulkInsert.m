function dbBulkInsert(db_name, db_table, tbl_fld, cell_data_ary)
%  PURPOSE:  Bulk insert data from cell array to database table
%  INPUTS:   db_Name    =  The database name of the destination [String]
%            db_table    = The database table name of the destination [String]
%            fieldNames  = List of field names of the destinated database
%                          table in same order as the columns presented in
%                          dataCellArr [Cells]
%            dataCellArr = Data to be inserted [Cell Array]
%   EXAMPLE: dbBulkInsert('dbo.bulktest', {'Date','Industry','Secid','val','Pct'}, dataCellArr, 'iGradeSQLDev1')
FTSASSERT(~isempty(cell_data_ary), 'The input cell array is empty');
if ischar(tbl_fld), tbl_fld = {tbl_fld}; end
[nrow, ncol] = size(cell_data_ary);
FTSASSERT(ncol == length(tbl_fld), 'data and field mismatch');
batch_size	= 1000;
fldlist = sprintf(',%s', tbl_fld{:});
sqlprefix = ['INSERT ' db_table '(' fldlist(2:end) ') '];

try
    %% get and check table structure
    db_server = GetDbServerByHostName(db_name);
    tbl_info = runSP('Model', 'dbo.usp_GetColumnInfo', {db_name, db_table}, db_server);
    [tf, loc] = ismember(lower(tbl_fld), lower(tbl_info.COLUMN_NAME));
    FTSASSERT(all(tf), 'Field name does not exist in table');
    tbl_fld_type = tbl_info.DATA_TYPE(loc);
    
    for i = 1:ncol
        fld_type = tbl_fld_type{i};
        X = cell_data_ary(:,i);
        
        if ~isempty(strfind(fld_type, 'date'))
            index = cellfun(@(c) any(~isnan(c)), X);
            if isempty(strfind(fld_type, 'time'))
                X(index) = cellstr(datestr(X(index), '''yyyy-mm-dd'''));
            else
                X(index) = cellstr(datestr(X(index), '''yyyy-mm-dd HH:MM:ss'''));
            end
        elseif ~isempty(strfind(fld_type, 'char'))
            for j = 1:nrow
                if ~isnan(X{j}), break; end  % prevent detecting invalid type due to first record being a NaN
            end
            if isnumeric(X{j})
                X = strtrim(cellstr(num2str(cell2mat(X))));
            else
                index = cellfun(@(c) any(~isnan(c)), X);
                X(index) = strrep(X(index), '''', ''''''); % skip single quote
            end
            X = strcat('''', X, '''');
        elseif ~isempty(strfind(fld_type, 'int')) || ...
               ~isempty(strfind(fld_type, 'bit'))
            X = cellstr(num2str(cell2mat(X),'%d'));
        elseif ~isempty(strfind(fld_type, 'float')) || ...
               ~isempty(strfind(fld_type, 'decimal')) || ...
               ~isempty(strfind(fld_type, 'real'))
            X = cellstr(num2str(cell2mat(X),'%.8g'));
        else  %% default to string if could not be specified
            X = strcat('''', X, '''');
        end
        if i == 1
            sqls = strcat({' union all select '}, X); 
        else
            sqls = strcat(sqls, ',', X);
        end
    end

    clear cell_data_ary;
    while ~isempty(sqls)
        n = min(batch_size, length(sqls));
        sqls{1} = sqls{1}(11:end);  % exclude ' union all'
        sql = [sqlprefix sqls{1:n}];
        sqls(1:n) = [];
        sql = strrep(sql, '''NaN''', 'Null');
        sql = strrep(sql, 'NaN', 'Null');
        runSP(db_name, sql, {}); 
    end
catch e
    rethrow(e);
end 

end
