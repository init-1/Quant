function modelfactorinfo = LoadModelFactorInfo_V3(strategyinfo, modelid, startdate, enddate, isprod)

if isprod == 1
    server = 'commonsqlprod2.';
else
    server = '';
end

strategyid = strategyinfo.strategyid{1};

switch strategyinfo.type
    case 'bld'
%         sql = ['Select distinct m.submodelid, msm.name, m.factorid, f.factortypeid from commonsqlprod2.quantstrategy.bld.modelfactormap m join commonsqlprod2.quantstrategy.bld.submodelparameter msm on m.modelid = msm.modelid '...
%             'and m.submodelid = msm.submodelid join fac.factormstr f '...
%             ,' on m.factorid = f.id where m.ModelId = ', num2str(modelid)...
%             ,' and m.isActive = 1 order by m.SubModelId, f.factortypeid, FactorId'];
        sql = ['Select distinct fw.submodelid, msm.name, fw.factorid, f.factortypeid from ',server,'quantstrategy.bld.facWeightTS fw join ',server,'quantstrategy.bld.submodelparameter msm on fw.modelid = msm.modelid '...
            'and fw.submodelid = msm.submodelid join fac.factormstr f '...
            ,' on fw.factorid = f.id where fw.ModelId = ', num2str(modelid)...
            ,' and fw.date between ''',startdate,''' and ''',enddate,''' order by fw.SubModelId, f.factortypeid, FactorId'];
    case 'mfs'
        sql = ['Select 1 as submodelid, ''UNIV'' as name, factorid, f.factortypeid from ',server,'quantstrategy.mfs.FactorPool m join ',server,'quantstrategy.fac.factormstr f '...
            ,'on m.factorid = f.id where strategyid = ''',strategyid,''' and isactive = 1 order by SubModelId, f.factortypeid, FactorId'];
end

modelfactorinfo = runSP('QuantStrategy', sql, []);

if ~iscell(modelfactorinfo.name)
    modelfactorinfo.name = {modelfactorinfo.name};
end
    

return