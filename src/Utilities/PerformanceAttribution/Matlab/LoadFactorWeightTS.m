function fts = LoadFactorWeightTS(modelid, submodelid, dtStart, dtEnd, strategyinfo, modelfactorinfo, isprod)
% FUNCTION: LoadFactorWeightTS
% DESCRIPTION: load factor weight stored in database for factor blending
% model
% INPUTS:
% OUTPUT:
%	fts		- a cell array The item time series, encapsulated as an object of 'myfints'
%	

if isprod == 1
    server = 'commonsqlprod2.';
else
    server = '';
end

switch strategyinfo.type
    case 'bld'
        sql = ['select date, lag, factorid, weight from ',server,'quantstrategy.bld.facweightts where modelid = '...
            , num2str(modelid), ' and submodelid = ', num2str(submodelid)...
            , ' and date between ''', dtStart, ''' and ''', dtEnd, ''' order by date, factorid, lag']; %order by lag, date, factorid 
    case 'facbldg'
        sql = ['select date, factorid, 0 as lag, weight from ',server,'quantstrategy.facbldg.facweightts where len(factorid) = 6 and modelid = '...
            , num2str(modelid), ' and submodelid = ', num2str(submodelid)...
            , ' and date between ''', dtStart, ''' and ''', dtEnd, ''' order by date, factorid']; %order by lag, date, factorid 
    case 'mfs'
        sql = ['select date, factorid, 0 as lag, weight from ',server,'quantstrategy.mfs.factorwgt where strategyid = ''', strategyinfo.strategyid{1}... 
            , ''' and date between ''', dtStart, ''' and ''', dtEnd, '''order by date, factorid'];
end

sqlRet = runSP('quantstrategy',sql,[]);

if isempty(sqlRet)
    % if factor weight doesn't exist, use equal weight
    factorid = modelfactorinfo.factorid(modelfactorinfo.submodelid == submodelid);
%     dateinfo = runSP('quantstrategy',['select min(Date) as mindate, max(Date) as maxdate from commonsqlprod2.quantstrategy.facbldg.facweightts where modelid =  ',num2str(modelid)...
%     , ' and date between ''', dtStart, ''' and ''', dtEnd, ''''],[]);
%     if ~isempty(dateinfo)
%         dtStart = dateinfo.mindate;
%         dtEnd = dateinfo.maxdate;
%     end
    w = 1/numel(factorid);
    dates = genDateSeries(dtStart, dtEnd, 'D', 'Busdays', 1);
    fts = myfints(dates, w*ones(numel(dates), numel(factorid)), factorid);
else
    vecDate = datenum(sqlRet.date);
    vecId = sqlRet.factorid;
    vecData = sqlRet.weight;
    if any(sqlRet.lag > 0) % more than 1 lag is used
        fid = strcat('L', Num2StrArray(sqlRet.lag, '%2.0f'));
    else
        fid = repmat({'WEIGHT'}, size(vecDate));
    end
    fts = mat2fts(vecDate, vecData, vecId, fid);
end

    
return 
