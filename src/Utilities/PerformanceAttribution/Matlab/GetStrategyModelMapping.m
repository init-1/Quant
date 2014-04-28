function modellist = GetStrategyModelMapping(strategyid, isprod)

if isprod == 1
    server = 'commonsqlprod2.';
else
    server = '';
end

if strcmpi(strategyid, 'MFS_EURSC') % european small cap
    modellist.modelid = 0;
    modellist.modelname = 'UNIV';
else
    if strcmpi(strategyid, 'FAC_APHD_TW')
        strategyid = 'FAC_APHD';
    end
    if isprod == 1
        modellist = runSP('QuantStrategy', ['select sm.modelid, mm.modelname from ',server,'quantstrategy.bld.strategymodel sm join ',server,'quantstrategy.bld.modelmstr mm on sm.modelid = mm.modelid '...
        'where strategyid = (select alphaid from ',server,'quantstrategy.dbo.strategymstr where id = ''',strategyid,''') order by sm.modelid'], {});
    else % isprod = 0, user can have strategyid that doesn't currently exist in strategymstr
        modellist = runSP('QuantStrategy', ['select sm.modelid, mm.modelname from ',server,'quantstrategy.bld.strategymodel sm join ',server,'quantstrategy.bld.modelmstr mm on sm.modelid = mm.modelid where strategyid = ''',strategyid,''' order by sm.modelid'], {});
    end
end

if ischar(modellist.modelname)
    modellist.modelname = {modellist.modelname};
end

end


