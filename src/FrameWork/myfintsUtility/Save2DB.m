function Save2DB(factorTS, updateMode)
% FUNCTION: Save2DB
% DESCRIPTION: Save the factor time series into data base
%   updateMode:
%     'incremental': only update new stuff not presented in DB
%        'complete': force to update the overlapping records between DB
%                    data and factorTS calculated in Matlab

if nargin < 2, updateMode = 'incremental'; end
FTSASSERT(isa(factorTS, 'FacBase'),'input factorTS is not a FacBase object');
FTSASSERT(ismember(lower(updateMode), {'incremental' 'complete'}), 'Unrecognized update mode');

%% Restructure the data set to insert into data base
isLive = factorTS.isLive;
secids = fieldnames(factorTS,1);
dates = cellstr(datestr(factorTS.dates,'yyyy-mm-dd'));

% convert to vector for inserting
[Dates_Col, quantId_Col, Data_Col] = fts2vec(factorTS, 1);

if strcmpi(updateMode, 'incremental') % delete the overlapping records which already exists in the DB
    try
        factorInDB = LoadFactorTS(secids, factorTS.id, dates{1}, dates{end}, isLive);
        %         % Method 1 - only check for overlapping secIds
        %         OverlapSecId = FieldId2QuantId(fieldnames(factorInDB,1));
        %         OverlapSecId = OverlapSecId(any(~isnan(fts2mat(factorInDB)),1));
        %         OverlapIdx = ismember(quantId, OverlapSecId);
        %         quantId = quantId(~OverlapIdx);
        %         matlabId = matlabId(~OverlapIdx);
        %         Data = Data(:,~OverlapIdx);
        %         if isempty(Data)
        %             disp('No data will be inserted after ignoring records existed in DB');
        %             return;
        %         end
        % Method 2 - check for both overlapping records and dates
        
        %%%Changed on 7th July to account for in the month values for
        %%%backtest mode.
        dates_union = union(factorInDB.dates,factorTS.dates);
        [factorInDB, factorTS] = aligndata(factorInDB, factorTS, dates_union);
        overlapIdx = reshape((~isnan(fts2mat(factorInDB))) | isnan(fts2mat(factorTS)), [numel(fts2mat(factorInDB)), 1]);
        if ~isempty(overlapIdx)
            Dates_Col(overlapIdx) = [];
            quantId_Col(overlapIdx) = [];
            Data_Col(overlapIdx) = [];
        end
    catch e
        if ~strcmpi(e.identifier, 'LOADDATA:NODATA')
            rethrow(e);
        end
    end
end

if isempty(Dates_Col)
    throw(MException('SAVE2DB:NO_NEED_INSERT', 'Nothing need to be inserted after removing NaN and already-in-DB records.'));
end

% Construct output cellarray
if isLive
    FTSASSERT(numel(unique(Dates_Col)) == 1);
    dbTable = 'fac.FactorTS_Live';
else
    dbTable = 'fac.FactorTS_BT';
end

% Align factorid
factorId_Col = repmat({factorTS.id}, [numel(quantId_Col),1]);
OutPut = [factorId_Col, quantId_Col, Dates_Col, num2cell(Data_Col)];

dbName = 'QuantStrategy';
% Clean existing data
secIdStr = strcat(',',quantId_Col);
dateStr = strcat(',',Dates_Col);
secIdStr = [secIdStr{:}];
dateStr = [dateStr{:}];
DB(dbName).runSql('fac.CleanFactorTableNew', factorTS.id, dateStr(2:end), secIdStr(2:end), isLive);
% Insert data
status = bulkinsert(dbName, dbTable, OutPut);
if status ~= 0
     throw(MException('SAVE2DB:BCP_FAILED', ['BCP for ' factorTS.id ' failed (bcp errno:' num2str(status) ').']));
end
end

function status = bulkinsert(db_name, db_table, cell_data_ary)
    if isempty(cell_data_ary)
        return;
    end

    delim = {char(9)};
    buf = strcat(cell_data_ary(:,1), delim, cell_data_ary(:,2), delim, cell_data_ary(:,3) ...
        , delim, strrep(cellstr(num2str(cell2mat(cell_data_ary(:,4)),16)),'NaN', ''), {char(10)});

    filename = ['\\igradesftp1\PUBLIC_TEMP\' 'BI_' db_name '.' db_table];
    fo = fopen([filename '.dat'], 'W');
    for i = 1:length(buf)
        fwrite(fo, buf{i});
    end
    fclose(fo);

    fo = fopen([filename '.fmt'], 'W');
    fprintf(fo, [...
        '9.0\r\n' ...
        '4\r\n' ...
        '1  SQLCHAR  0  100  "\\t" 1  FactorId    SQL_Latin1_General_CP1_CI_AS\r\n' ...
        '2  SQLCHAR  0  100  "\\t" 2  SecId       SQL_Latin1_General_CP1_CI_AS\r\n' ...
        '3  SQLCHAR  0  10   "\\t" 3  Date        ""\r\n' ...
        '4  SQLFLT8  0  20   "\\n" 4  NumValue    ""\r\n']);
    fclose(fo);

    cmd = ['bcp ' db_name '.' db_table ' in ' filename '.dat -f' filename '.fmt '...
        '-S' GetDbServerByHostName(db_name) ' -T > nul'];
    status = system(cmd);
    delete([filename '.dat'], [filename '.fmt']);
end
