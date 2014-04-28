function [strategyinfo, aggid] = LoadStrategyInfo_V3(strategyid, isprod)

if isprod == 1
    server = 'commonsqlprod2.';
else
    server = '';
end

if strcmpi(strategyid, 'MFS_EURSC') % european small cap
    strategyinfo = runSP('QuantStrategy',['select strategyid, aggid, 0 as modelid, ''INDEX'' as modelname from ',server,'quantstrategy.mfs.strategymstr where strategyid = ''', strategyid, ''''],[]);
    strategyinfo.type = 'mfs';
else
    if strcmpi(strategyid, 'FAC_APHD_TW')
        strategyid = 'FAC_APHD';
    end
    if isprod == 1
        strategyinfo = runSP('QuantStrategy', ['select ''',strategyid,''' as strategyid, s.aggid, sm.modelid, mm.modelname from ',server,'quantstrategy.dbo.strategymstr s join ',server,'quantstrategy.bld.strategymodel sm on s.alphaid = sm.strategyid join ',server,'quantstrategy.bld.modelmstr mm on sm.modelid = mm.modelid '...
        ' where s.id = ''',strategyid,''' order by sm.modelid'], {});
%     else % isprod = 0, user can have strategyid that doesn't currently exist in strategymstr
%         strategyinfo = runSP('QuantStrategy', ['select sm.modelid, mm.modelname from ',server,'quantstrategy.bld.strategymodel sm join ',server,'quantstrategy.bld.modelmstr mm on sm.modelid = mm.modelid where strategyid = ''',strategyid,''' order by sm.modelid'], {});
    end
    strategyinfo.type = 'bld';
end

if ischar(strategyinfo.strategyid)
    strategyinfo.strategyid = {strategyinfo.strategyid};
    strategyinfo.aggid = {strategyinfo.aggid};
    strategyinfo.modelname = {strategyinfo.modelname};
end

aggid = strategyinfo.aggid{1};

end


