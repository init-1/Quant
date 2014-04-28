function res = GetDbServerByHostName(dbName)

%% Comments 
%
%  PURPOSE: Get SQL Database Connection String;
%  INPUTS:  dbServer = Database server
%           dbName   = Database name
%  OUTPUT:  return SQL database connection string: a string containing information for connecting to data source
%           e.g.: Provider=SQLOLEDB;Data Source=IGRADESQLDEV1;Initial Catalog=Report;User Id=dba;Password=123Igrade456;
%  
    persistent hostName;
    persistent per_dbName;
    persistent per_DB_SERVER;

    if strcmpi(dbName, 'Model')
        per_DB_SERVER = 'iGradeSQLDev1';
    else
        if isempty(hostName)
            hostName = getenv('Computername');
        end

        if ~strcmp(per_dbName, dbName) %if isempty(DB_SERVER)
            per_dbName = dbName;
            dbServerStruct = runSP('Model', 'dbo.usp_GetHostDbServerMapping', {hostName, dbName});

            if isempty(dbServerStruct) 
                error('No dbServer found for this host name; please contact your administrator to setup the dbServer for this host.');
            elseif size(dbServerStruct.DbServer,1) > 1
                error(['Database ' dbName ' is not unique across database servers' ]');
            else
                per_DB_SERVER = dbServerStruct.DbServer;
            end
        end
    end
    
    res = per_DB_SERVER; %DB_SERVER;
end

    