function modelinfo = LoadModelInfo(strategyinfo, modelid, isprod)

if isprod == 1
    server = 'commonsqlprod2.';
else
    server = '';
end

strategyid = strategyinfo.strategyid{1};

switch strategyinfo.type
    case 'mfs'
        modelinfo = runSP('QuantStrategy',['select 0 as modelid, ''INDEX'' as modelname, 1 as submodelid, ''INDEX'' as name, 0 as lag, 1 as gicslevel from ',server,'quantstrategy.mfs.strategymstr where strategyid = ''', strategyid, ''''],[]);
    otherwise
        modelinfo = runSP('QuantStrategy',['select distinct mm.modelname, mm.modelid, smp.submodelid, smp.name, smp.lag, smp.gicslevel, cast(left((case when msm.sector = ''ALL'' then NULL else msm.sector end),2) as float) sector, smp.FactorBucket, smp.BucketNum '...
            ,'from ',server,'quantstrategy.bld.modelmstr mm join ',server,'quantstrategy.bld.subModelParameter smp on mm.modelid = smp.modelid join ',server,'quantstrategy.bld.modelsubmodel msm on mm.modelid = msm.modelid and smp.submodelid = msm.submodelid '...
            ,'where msm.isactive = 1 and msm.submodelid > 0 and mm.modelid = ', num2str(modelid), ' order by smp.submodelid'],[]);
        
        if ~iscell(modelinfo.FactorBucket), modelinfo.FactorBucket = {modelinfo.FactorBucket}; end
end

return