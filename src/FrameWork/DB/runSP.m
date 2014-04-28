function ResultADOrs = runSP(dbName, spName, params, dbServer)
%% Comments
%
%  PURPOSE: Run the Stored Procedure
%  INPUTS:  dbName      = Database name for database connection string
%           spName      = Name of the stored procedure one would like to run
%           inputParam  = a cell array of stored procedure parameters values
%                         e.g.: {1 '2008-09-30'}
%   OUTPUT: Recordset returned by the stored procedure in Structure of
%           Array format with column names as fields.
%
if nargin < 4 || isempty(dbServer)
    dbServer = GetDbServerByHostName(dbName);
end
%%res = ['Provider=SQLOLEDB;Data Source=' dbServer ';Initial Catalog=' dbName ';User Id=dba;Password=123Igrade456;'];
connStr = ['Provider=SQLOLEDB;Data Source=' dbServer ';Initial Catalog=' dbName ';Integrated Security=SSPI;'];

isInitConn = false;
isInitCmd  = false;
isInitADOrs = false;
ok = true;

try
%% create ADO Connection
    ADOconn = actxserver('ADODB.Connection');
    isInitConn = true;
    ADOconn.ConnectionString = connStr;
    ADOconn.ConnectionTimeout = 600;
    ADOconn.CommandTimeout = 600;
    ADOconn.CursorLocation = 2; % adUseServer: indicates that the data provider or driver-supplied cursor is used
    ADOconn.Open;

%% open ADO Recordset
    ADOcmd = actxserver('ADODB.Command');
    isInitCmd = true;
    ADOcmd.CommandTimeout = 0;
    ADOcmd.ActiveConnection = ADOconn;
    ADOcmd.CommandType = 4;    %adCmdStoredProc; 1 = adCmdText
    ADOcmd.CommandText = spName;
    ADOcmd.Prepared = 1;
    
    if ismember(' ', spName)
        ADOcmd.CommandType = 1;
    else
        ADOcmd.CommandType = 4;
        ADOcmd.Parameters.Refresh;
        %% Set Parameters Values if any
        n = length(params);
        FTSASSERT(n == ADOcmd.Parameters.Count - 1, ...
            sprintf('SQL Error: %s\n Unexpected number of parameters: %d expected, %d provided',spName,ADOcmd.Parameters.Count,n));
        for i = 1:n
            ADOcmd.Parameters.Item(i).Value = params{i};
        end
    end
    
    ADOrs = ADOcmd.Execute();
    isInitADOrs = true;
    
    ResultADOrs = [];
    %% check recordset
    if ADOrs.state == 0 || ~(ADOrs.BOF == 0 && ADOrs.EOF == 0)
        ADOrsRows = [];
    else    
        %% Format Data
        ADOrsRows = ADOrs.GetRows;
    end    
    
    if isempty(ADOrsRows)
       ResultADOrs = [];
    else
        ADOrsRows = ADOrsRows';
        %% Convert Data into Struct
        for iField = 1:ADOrs.Fields.Count
            fld     = ADOrs.Fields.Item(iField-1);
            fldName = regexprep(fld.Name, '\s|-', '_');

            if ismember(upper(fld.Type), {...
               'ADBIGINT' 'ADINTEGER' 'ADSMALLINT' 'ADTINYIN' 'ADUNSIGNEDBIGINT'...
               'ADUNSIGNEDINT' 'ADUNSIGNEDSMALLINT' 'ADUNSIGNEDTINYINT' ...
               'ADDECIMAL' 'ADDOUBLE' 'ADNUMERIC' 'ADSINGLE' 'ADVARNUMERIC'})
                row = ADOrsRows(:,iField);
                if ischar(row{1})
                    ResultADOrs.(fldName) = str2double(row);
                else
                    ResultADOrs.(fldName) = cellfun(@(x)double(x),row);
                end
            else
                if size(ADOrsRows, 1) > 1
                    ResultADOrs.(fldName) = ADOrsRows(:,iField);
                else
                    ResultADOrs.(fldName) = ADOrsRows{1,iField};
                end
            end
        end
    end

catch e
    ok = false;
end

%%%% Clean the mess
if isInitADOrs 
    if ADOrs.state > 0, ADOrs.Close; end
end

if isInitCmd, ADOcmd.delete; end

if isInitConn 
    if ADOconn.state > 0, ADOconn.Close; end
    ADOconn.delete;
end

if ~ok, rethrow(e); end

end
