function fts=LoadAlphaTS(strategyinfo, startdate, enddate, isprod)

if isprod == 1
    server = 'commonsqlprod2.';
else
    server = '';
end

strategyid = strategyinfo.strategyid{1};

if strcmpi(strategyid, 'FAC_APHD_TW')
    strategyid = 'FAC_APHD';
end

switch strategyinfo.type
    case 'bld'
        sqlRet = runSP('quantstrategy'...
            ,['select date, secid, alpha as value from ',server,'quantstrategy.bld.alphats where strategyid ='''...
            ,strategyid,''' and date between ''', startdate, ''' and ''', enddate...
            , ''' order by date, secid'],[]);
        if isempty(sqlRet)
            sqlRet = runSP('quantstrategy'...
                ,['select date, secid, alpha as value from quantstrategy.bld.alphats where strategyid ='''...
                ,strategyid,''' and date between ''', startdate, ''' and ''', enddate...
                , ''' order by date, secid'],[]);   
        end
    case 'facbldg'
        sqlRet = runSP('quantstrategy'...
            ,['select date, secid, alpha as value from ',server,'quantstrategy.facbldg.alphats where modelid ='''...
            ,num2str(strategyinfo.modelid(1)),''' and date between ''', startdate, ''' and ''', enddate...
            , ''' and submodelid = 0 order by date, secid'],[]);
        if isempty(sqlRet)
            sqlRet = runSP('quantstrategy'...
            ,['select date, secid, alpha as value from ',server,'quantstrategy.facbldg.alphats where modelid ='''...
            ,num2str(strategyinfo.modelid(1)),''' and date between ''', startdate, ''' and ''', enddate...
            , ''' and submodelid = 0 order by date, secid'],[]);
        end
    case 'mfs'
        sqlRet = runSP('quantstrategy'...
            ,['select date, secid, value from ',server,'quantstrategy.mfs.alphats where strategyid ='''...
            ,strategyid,''' and date between ''', startdate, ''' and ''', enddate...
            , ''' order by date, secid'],[]); 
end


vecDate = sqlRet.date;
vecId = sqlRet.secid;
vecData = sqlRet.value;
fid = cell(size(vecDate));
fid(:) = {'ALPHA'};

fts = mat2fts(datenum(vecDate), vecData, QuantId2FieldId(vecId), fid);
fts = fts{:};


return
