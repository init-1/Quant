classdef AXDBTemplate
    methods (Static)
        function opt = optimization(batchid)
            % Load DataSet
            db = DB('QuantTrading');
            bmstr = db.runSql('axioma.GetAXBatch',batchid,'Mstr');
            bitem = db.runSql('axioma.GetAXBatch',batchid,'BatchItem');
            dates = datenum(bitem.perioddate);
            T = length(dates);
         
            cacheFileName = ['AXDS-' num2str(bmstr.datasetid) '.mat'];
            if exist(cacheFileName, 'file')
                TRACE('Dataset (id=%d) cache found. No loading needed!\n', bmstr.datasetid);
                load(cacheFileName);
            else
                ds = AXDBTemplate.dataset(bmstr.datasetid, dates);
                save(cacheFileName, 'ds');
            end

            % Load Rebalacings and Strategies
            reb = cell(1,T);
            str = cell(1,T);
            for t = 1:T
                TRACE('Loading frontier (id=%d) for %s ... ', bitem.frontierid(t), datestr(dates(t),'yyyy-mm-dd'));
                [reb{t}, str{t}] = AXDBTemplate.frontier(bitem.frontierid(t));
                TRACE('done\n');
            end    
            reb = containers.Map(dates, reb);
            str = containers.Map(dates, str);

            opt = AXOptimization(ds, str, reb);
        end
        
        function saveSolution(results, batchid)
            TRACE('Saving solutions to database ... ');
            ad.batchid = batchid;
            dates = cell2mat(keys(results));
            for d = dates
                ad.perioddate = datestr(d, 'yyyy-mm-dd');
                solutions = results(d);
                for sol = solutions(:)'
                    ad.frontierid = sol.frontierid;
                    ad.rebalanceid = sol.rebalanceid;
                    if sol.solts.hasSolution
                        save2db(sol.pfinit,  'SolutionInitial', 'secid', ad);
                        save2db(sol.pffinal, 'SolutionFinal',   'secid', ad);
                        save2db(sol.trd,     'SolutionTrade',   'secid', ad);
                        cnames = fieldnames(sol.vios);
                        ad_ = ad;
                        for i = 1:numel(cnames)
                            ad_.constraintname = cnames{i};
                            ad_.constrainttype = sol.vios.(cnames{i}).desc;
                            ad_.unit = char(sol.vios.(cnames{i}).unit);
                            save2db(sol.vios.(cnames{i}), 'SolutionViolation', 'name', ad_);
                        end
                        save2db(sol.summary, 'SolutionSummary', 'item',  ad);
                    end
                    save2db(sol.solts, 'SolutionTS', '', ad);
                end
                
                db = DB('QuantTrading');
                bestSol = db.runSql('axioma.GetAXBestSolution', batchid, ad.perioddate);
                db.runSql(['update axioma.FrontierTS set bestsolutionid=' num2str(bestSol.id) ...
                    ' where batchid=' num2str(batchid) ' and perioddate=' ad.perioddate ...
                    ' and frontierid=' num2str(ad.frontierid)]);
            end
            TRACE('done\n');
        end
        
        function ds = dataset(id,dates)
            LOGFMT = '%12.12s %s\n';
            TRACE('Loading dataset (id=%d) ...\n', id);
            db = DB('QuantTrading');
            mstr = db.runSql('axioma.GetAXDataSet',id,'Mstr');
            uni = textscan(mstr.universe,'%s','Delimiter',',');
            ds = AXDataSet(mstr.islive,dates,uni{1});
            
            %% Data Items
            try
                ditem = db.runSql('axioma.GetAXDataSet',id,'DataItem');
                ditem = checkcell(ditem);
                for i=1:length(ditem.id)
                    TRACE(LOGFMT, 'GROUP', ditem.id{i});
                    source = textscan(ditem.source{i},'%s','Delimiter',',');
                    sourceid = textscan(ditem.sourceid{i},'%s','Delimiter',',');
                    backfilldays  = textscan(ditem.backfilldays{i},'%f','Delimiter',',');
                    if ~isnan(ditem.funhandle{i})
                        fts = AXDBTemplate.LoadDataItem(ds,source{1},sourceid{1},backfilldays{1},Unit.(upper(ditem.unit{i})),str2func(ditem.funhandle{i}));
                    else
                        fts = AXDBTemplate.LoadDataItem(ds,source{1},sourceid{1},backfilldays{1},Unit.(upper(ditem.unit{i})));
                    end
                    if ~isnan(ditem.normalize{i})
                        fts = normalize(fts,'method',ditem.normalize{i});
                    end
                    ds(ditem.id{i}) = fts;
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Benchmarks
            try
                dbench = db.runSql('axioma.GetAXDataset',id,'Benchmark');
                dbench = checkcell(dbench);
                for i=1:length(dbench.id)
                    TRACE(LOGFMT, 'GROUP', dbench.id{i});
                    switch lower(dbench.source{i})
                        case {'table'}
                            fts = ds.loadBenchmark(dbench.input{i});
                            ds.add(['X' dbench.input{i}], fts, 'BENCHMARK');
                        case {'sproc'}
                            if ~isnan(dbench.param{i})
                                param = textscan(dbench.param{i},'%s','Delimiter',',');
                                param = param{1};
                                AXDBTemplate.LoadBenchmark(ds,dbench.id{i},dbench.input{i},param{:});
                            else
                                AXDBTemplate.LoadBenchmark(ds,dbench.id{i},dbench.input{i})
                            end
                    end
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Classifications
            try
                dclass = db.runSql('axioma.GetAXDataSet',id,'Classification');
                dclass = checkcell(dclass);
                for i=1:length(dclass.id)
                    TRACE(LOGFMT, 'METAGROUP', dclass.id{i});
                    if ~isnan(dclass.param{i})
                        param = textscan(dclass.param{i},'%s','Delimiter',',');
                        param = param{1};
                        AXDBTemplate.LoadAttribute(ds,dclass.id{i},Unit.NUMBER,'METAGROUP',dclass.input{i},param{:});
                    else
                        AXDBTemplate.LoadAttribute(ds,dclass.id{i},Unit.NUMBER,'METAGROUP',dclass.input{i});
                    end
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Classifications - Bucket
            try
                dbuck = db.runSql('axioma.GetAXDataSet',id,'Bucket');
                dbuck = checkcell(dbuck);
                for i=1:length(dbuck.id)
                    TRACE(LOGFMT, 'METAGROUP', dbuck.id{i});
                    source = textscan(dbuck.source{i},'%s','Delimiter',',');
                    sourceid = textscan(dbuck.sourceid{i},'%s','Delimiter',',');
                    backfilldays = textscan(dbuck.backfilldays{i},'%f','Delimiter',',');
                    if ~isnan(dbuck.funhandle{i})
                        fts = AXDBTemplate.LoadDataItem(ds,source{1},sourceid{1},backfilldays{1},Unit.TEXT,str2func(dbuck.funhandle{i}));
                    else
                        fts = AXDBTemplate.LoadDataItem(ds,source{1},sourceid{1},backfilldays{1},Unit.TEXT);
                    end
                    fts = normalize(fts,'method',dbuck.method{i},'mode','descend');
                    if ~isnan(dbuck.classification{i})
                        fts = AXDBTemplate.addPrefix(ds,dbuck.classification{i},fts);
                    end
                    fts.unit = Unit.TEXT;
                    ds.add(dbuck.id{i},fts,'METAGROUP');
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end            
            %% Restricted Lists - Account
            try
                daccr = db.runSql('axioma.GetAXDataSet',id,'AccRestricted');
                daccr = checkcell(daccr);
                for i=1:length(daccr.id)
                    TRACE(LOGFMT, 'GROUP', daccr.id{i});
                    acclist = textscan(daccr.acclist{i},'%s','Delimiter',',');
                    ds.addAccountRestricted(daccr.id{i},acclist{1});
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Restricted Lists - Customized
            try
                dcusr = db.runSql('axioma.GetAXDataSet',id,'CusRestricted');
                dcusr = checkcell(dcusr);
                for i=1:length(dcusr.id)
                    TRACE(LOGFMT, 'GROUP', dcusr.id{i});
                    custype = textscan(dcusr.custype{i},'%s','Delimiter',',');
                    typename = textscan(dcusr.typename{i},'%s','Delimiter',',');
                    ds.addCustomRestricted(dcusr.id{i},custype{1},typename{1});
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Alpha
            try
                dalpha = db.runSql('axioma.GetAXDataSet',id,'Alpha');
                dalpha = checkcell(dalpha);
                for i=1:length(dalpha.id)
                    TRACE(LOGFMT, 'GROUP', dalpha.id{i});
                    switch lower(dalpha.source{i})
                        case {'table'}
                            ds.addAlpha(dalpha.id{i},dalpha.input{i});
                        case {'sproc'}
                            if ~isnan(dalpha.param{i})
                                param = textscan(dalpha.param{i},'%s','Delimiter',',');
                                param = param{1};
                                AXDBTemplate.LoadAttribute(ds,dalpha.id{i},Unit.NUMBER,'GROUP',dalpha.input{i},param{:});
                            else
                                AXDBTemplate.LoadAttribute(ds,dalpha.id{i},Unit.NUMBER,'GROUP',dalpha.input{i})
                            end
                    end
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Account
            try
                dacc = db.runSql('axioma.GetAXDataSet',id,'Account');
                dacc = checkcell(dacc);
                for i=1:length(dacc.id);
                    TRACE(LOGFMT, 'ACCOUNT', dacc.id{i});
                    switch lower(dacc.source{i})
                        case {'cash'}
                            fts = myfints(ds.dates,repmat(str2double(dacc.input{i}),size(ds.dates)),'CASH');
                            ds.add(dacc.id{i}, fts, 'ACCOUNT');
                        case {'table'}
                            input = textscan(dacc.input{i},'%s','Delimiter',',');
                            input = input{1};
                            ds.addAccount(dacc.id{i},input{:});
                        case {'sproc'}
                            if ~isnan(dacc.param{i});
                                param = textscan(dalpha.param{i},'%s','Delimiter',',');
                                param = param{1};
                                AXDBTemplate.LoadAttribute(ds,dacc.id{i},Unit.SHARES,'ACCOUNT',dacc.input{i},param{:});
                            else
                                AXDBTemplate.LoadAttribute(ds,dacc.id{i},Unit.SHARES,'ACCOUNT',dacc.input{i})
                            end
                    end
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Risk Models
            try
                drisk = db.runSql('axioma.GetAXDataSet',id,'RiskModel');
                drisk = checkcell(drisk);
                for i=1:length(drisk.id)
                    TRACE(LOGFMT, 'RISKMODEL', drisk.id{i});
                    switch lower(drisk.model{i})
                        case {'barra'}
                            RiskBarra(drisk.id{i},ds);
                        case {'ema'}
                            RiskEMA(drisk.id{i},ds);
                    end                  
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Transaction Cost Models
            try
                dtcm = db.runSql('axioma.GetAXDataSet',id,'TCModel');
                dtcm = checkcell(dtcm);
                for i=1:length(dtcm.id)
                    TRACE(LOGFMT, 'TCMODEL', dtcm.id{i});
                    switch lower(dtcm.model{i})
                        case {'qsg'}
                            TCQSG(dtcm.id{i},ds,str2double(dtcm.fixedcost{i}),dtcm.currency{i});
                        case {'simple'}
                            TCSimple(dtcm.id{i},ds,str2double(dtcm.fixedcost{i}),dtcm.currency{i});
                        case {'flat'}
                            TCFlat(dtcm.id{i},ds,str2double(dtcm.fixedcost{i}),dtcm.currency{i});
                    end
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Partitions
            try
                dpart = db.runSql('axioma.GetAXDataSet',id,'Partition');
                dpart = checkcell(dpart);
                for i=1:length(dpart.id)
                    TRACE(LOGFMT, 'METAGROUP', dpart.id{i});
                    AXDBTemplate.LoadPartition(ds,dpart.id{i},dpart.base{i},dpart.classification{i});
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
            %% Asset Sets
            try
                daset = db.runSql('axioma.GetAXDataSet',id,'AssetSet');
                daset = checkcell(daset);
                for i=1:length(daset.id)
                    TRACE(LOGFMT, 'SET', daset.id{i});
                    incexc = textscan(daset.incexc{i},'%f','Delimiter',',');
                    incexc = incexc{1};
                    group = textscan(daset.group{i},'%s','Delimiter',',');
                    group = upper(group{1});
                    fts = myfints(ds.dates,repmat(incexc',length(ds.dates),1),group');
                    ds.add(daset.id{i},fts,'SET');
                end
            catch e
                if ~strcmp(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
            end
        end
        
        function cnsts = constraint(id)
            cons = DB('QuantTrading').runSql('axioma.GetAXConstraint',id,'ConstraintItem');
            attriblist = unique(cons.attribute);
            cnsts = cell(length(attriblist),1);
            for i=1:length(attriblist)
                items = cons.item(strcmp(cons.attribute,attriblist{i}));
                value = cons.value(strcmp(cons.attribute,attriblist{i}));
                cnsts{i} = AXConstraint(attriblist{i},value{strcmp(items,'type')});
                % remove type
                value = value(~strcmpi(items,'type'));
                items = items(~strcmpi(items,'type'));
                for j=1:length(items)
                    switch lower(items{j})
                        case {'priority','selection','desc'}
                            if ~isnan(str2double(value{j}))
                                cnsts{i}.(lower(items{j})) = str2double(value{j});
                            else
                                val = textscan(upper(value{j}),'%s','Delimiter',',');
                                cnsts{i}.(lower(items{j})) = val{1};
                            end
                        case {'isenabled'}
                            if strcmpi(value{j},'true')
                                value{j} = true;
                            elseif strcmpi(value{j}, 'false')
                                value{j} = false;
                            else
                                value{j} = str2double(value{j});
                            end
                            cnsts{i}.isEnabled = value{j};
                        case {'unit'}
                            cnsts{i}.UNIT = Unit.(upper(value{j}));
                        otherwise
                            if ~isnan(str2double(value{j}))
                                cnsts{i}.(upper(items{j})) = str2double(value{j});
                            else
                                cnsts{i}.(upper(items{j})) = upper(value{j});
                            end
                    end
                end
            end
        end
        
        function obj = objective(id)
            db = DB('QuantTrading');
            mstr = db.runSql('axioma.GetAXObjective',id,'Mstr');
            obj = AXObjective(mstr.name,upper(mstr.objectivesense));
            o = db.runSql('axioma.GetAXObjective',id,'ObjectiveItem');
            attriblist = unique(o.attribute);
            for i=1:length(attriblist)
                item = o.item(strcmp(o.attribute,attriblist{i}));
                value = o.value(strcmp(o.attribute,attriblist{i}));
                switch lower(value{strcmpi(item,'type')});
                    case {'expectedreturnobjective'}
                        obj = obj.addExpectedReturnObjective(attriblist{i},upper(value{strcmpi(item,'alphagroup')}),str2double(value{strcmpi(item,'weight')}));
                    case {'linearshortobjective'}
                        obj = obj.addLinearShortObjective(attriblist{i},upper(value{strcmpi(item,'shortcost')}),str2double(value{strcmpi(item,'weight')}));
                    case {'linearshortsellobjective'}
                        obj = obj.addLinearShortSellObjective(attriblist{i},upper(value{strcmpi(item,'shortsellcost')}),str2double(value{strcmpi(item,'weight')}));
                    case {'marketimpactobjective'}
                        obj = obj.addMarketImpactObjective(attriblist{i},upper(value{strcmpi(item,'buyimpactgroup')}),upper(value{strcmpi(item,'sellimpactgroup')}),upper(value{strcmpi(item,'marketimpacttype')}),str2double(value{strcmpi(item,'weight')}));
                    case {'riskalphafactorobjective'}
                        obj = obj.addRiskAlphaFactorObjective(attriblist{i},upper(value{strcmpi(item,'benchmarkgroup')}),upper(value{strcmpi(item,'riskmodel')}),str2double(value{strcmpi(item,'alphafactorvol')}),str2double(value{strcmpi(item,'weight')}));
                    case {'riskobjective'}
                        obj = obj.addRiskObjective(attriblist{i},upper(value{strcmpi(item,'benchmarkgroup')}),upper(value{strcmpi(item,'riskmodel')}),str2double(value{strcmpi(item,'weight')}));
                    case {'robust'}
                        obj = obj.addRobust(attriblist{i},upper(value{strcmpi(item,'alphagroup')}),str2double(value{strcmpi(item,'kappa')}),upper(value{strcmpi(item,'riskmodel')}),str2double(value{strcmpi(item,'weight')}));
                    case {'transactioncostobjective'}
                        obj = obj.addTransactionCostObjective(attriblist{i},str2double(value{strcmpi(item,'weight')}));
                    case {'variancealphafactorobjective'}
                        obj = obj.addVarianceAlphaFactorObjective(attriblist{i},upper(value{strcmpi(item,'benchmarkgroup')}),upper(value{strcmpi(item,'benchmarkgroup')}),upper(value{strcmpi(item,'riskmodel')}),str2double(value{strcmpi(item,'alphafactorvol')}),str2double(value{strcmpi(item,'weight')}));
                    case {'varianceobjective'}
                        obj = obj.addVarianceObjective(attriblist{i},upper(value{strcmpi(item,'benchmarkgroup')}),upper(value{strcmpi(item,'riskmodel')}),str2double(value{strcmpi(item,'weight')}));
                end
            end
        end
        
        function [rebal, str] = frontier(id)
            db = DB('QuantTrading');
            mstr = db.runSql('axioma.GetAXFrontier',id,'Mstr');
            if isnan(mstr.prevalpha)
                prevalpha = '';
            else
                prevalpha = mstr.prevalpha;
            end
            rebal = AXRebalancing(mstr.name ...
                , 'DBID', id ...
                , 'benchmarkId', upper(mstr.benchmark) ...
                , 'roundlotsId', upper(mstr.roundlotgroup) ...
                , 'accountId', upper(mstr.account) ...
                , 'alphaId', upper(mstr.alpha) ...
                , 'prevalphaId',upper(prevalpha) ...
                , 'betaId' , upper(mstr.beta) ...
                , 'priceId', upper(mstr.price) ...
                , 'riskmodelId', upper(mstr.riskmodel) ...
                , 'tcmodelId', upper(mstr.tcmodel) ...
                , 'cashflow', mstr.cashflow ...
                , 'minruntime', mstr.runtimemin ...
                , 'maxruntime', mstr.runtimemax ...
                , 'budgetsize', mstr.budgetsize ...
                , 'volumeId', mstr.volume);
            strdb = db.runSql('axioma.GetAXFrontier',id,'FrontierItem');
            strdb = checkcell(strdb);
            lu_inc = textscan(upper(mstr.lu_inc),'%s','Delimiter',',');
            lu_inc = lu_inc{1};
            if ~isnan(mstr.lu_exc)
                lu_exc = textscan(upper(mstr.lu_exc),'%s','Delimiter',',');
                lu_exc = lu_exc{1};
            else
                lu_exc = {};
            end
            for i=length(strdb.id):-1:1
                str(i) = AXStrategy(upper(strdb.strategy{i}) ...
                    , 'DBID', strdb.id{i} ...
                    , 'objective', AXDBTemplate.objective(strdb.objectiveid{i}) ...
                    , 'constraints', AXDBTemplate.constraint(strdb.constraintid{i}) ...
                    , 'isConstraintHierarchy', strdb.enablehierarchy{i} ...
                    , 'isAllowCrossover', mstr.isshort ...
                    , 'isAllowShorting', mstr.isshort ...
                    , 'included', lu_inc ...
                    , 'excluded', lu_exc); % ...
                    %, 'isMarketNeutral', mstr.ismarketneutral);
            end
        end
        
        function fts = LoadDataItem(ds,source,sourceid,backfilldays,unit,funhandle)
            %% Single Item
            % ds('NAME') = AXDBTemplate.LoadDataItem(ds,'SecTS',1051,7,Unit.PRICE);
            %% Single Item with Scalar Multiple
            % ds('NAME') = AXDBTemplate.LoadDataItem(ds,'SecTS',1051,7,Unit.PRICE,@(x) x*0.05);
            %% Single Item operating on Single Item
            % ds('NAME') = AXDBTemplate.LoadDataItem(ds,{'SecTS','SecTS'},{1051,159},{Unit.PRICE,Unit.NUMBER},@(x,y) ftsmovavg(x.*y,30))
            assert(all(ismember(lower(source),{'sects','factor','raw'})),'Invalid source.');
            assert(all(cellfun(@length, {sourceid, backfilldays}) == length(source)),'Input cell arrays must be of same length.');
            assert(length(unit)==1,'Only one unit is allowed.');
            if length(source) > 1
                assert(nargin == 6,'Function Handle must exist if there is more than one data item.');
            end
            ftsarr = cell(length(source),1);
            for i=1:length(source)
                switch lower(source{i})
                    case {'sects'}
                        ftsarr{i} = ds.loadSecTS(sourceid{i},backfilldays(i),unit);
                    case {'factor'}
                        ftsarr{i} = ds.loadFactor(sourceid{i},backfilldays(i),unit);
                    case {'raw'}
                        ftsarr{i} = ds.loadRawTS(sourceid{i},backfilldays(i),unit);
                end
            end
            [ftsarr{:}] = aligndates(ftsarr{:},ftsarr{1}.dates);
            if nargin == 6
                assert(length(source) == nargin(funhandle),'Invalid function handle or number of data items.');
                fts = funhandle(ftsarr{:});
            else
                fts = ftsarr{1};
            end
        end
        
        function fts = addPrefix(ds,field,data)
            dates = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},ds.dates);
            uni = ds.getUniverse;
            idlist = sprintf(',%s',uni{:,1});
            datelist = sprintf(',%s',dates{:});
            ret = DB('QuantTrading').runSql('axapi.getSecMStr',idlist(2:end),datelist(2:end),field);
            class = mat2xts(datenum(ret.date),ret.value,ret.id);
            [class data] = aligndata(class,data);
            data = uniftsfun(data,@(b) mat2cell(num2str(b,'%1.1d'),ones(size(b,1),1),ones(size(b,2),1)));
            fts = biftsfun(class,data,@(x,y) strcat(x,'_',y));
        end
        
        function ds = LoadPartition(ds,name,baseset,classification)
            base = ds(upper(baseset));
            class = ds(upper(classification));
            [base, class] = aligndata(base,class,base.dates);
            ux = unique(fts2mat(class));
            for i=1:length(ux);
                basetmp = base;
                basetmp(strcmp(fts2mat(class),ux{i})) = 0;
                ds.add([upper(name) '_' ux{i}],basetmp,'GROUP');
            end
            ux = cellfun(@(c) {[name '_' c]},ux);
            fts = myfints(base.dates,ones(length(base.dates),length(ux)),ux);
            ds.add(upper(name),fts,'COLLECTION');
        end
        
        function ds = LoadBenchmark(ds,name,sproc,varargin)
            dates = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},ds.dates);
            datelist = sprintf(',%s',dates{:});
            ret = DB('QuantTrading').runSql(sproc,datelist(2:end),varargin{:});
            fts = mat2xts(datenum(ret.date),ret.value,ret.id);
            fts.unit = Unit.PERCENT;
            ds.add(upper(name), fts, 'BENCHMARK');
        end
        
        function ds = LoadAttribute(ds,name,unit,type,sproc,varargin)
            dates = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},ds.dates);
            uni = ds.getUniverse;
            idlist = sprintf(',%s',uni{:,1});
            datelist = sprintf(',%s',dates{:});
            ret = DB('QuantTrading').runSql(sproc,idlist(2:end),datelist(2:end),varargin{:});
            fts = mat2xts(datenum(ret.date),ret.value,ret.id);
            fts.unit = unit;
            ds.add(name, fts, upper(type));
        end
    end
end

function save2db(xtsdata, tblname, idfld, additional)
    % data should be an xts object
    % Iterate through the first field dimension (corresponding to rows in table)
    flds = fieldnames(additional);
    body = cell(1, numel(flds));
    clause = '';
    for i = 1:length(flds)
        body(1,i) = {additional.(flds{i})};
        if ischar(body{1,i})
            clause = [clause ' and ' flds{i} '=''' body{:,i} '''']; %#ok<AGROW>
        else
            clause = [clause ' and ' flds{i} '=' num2str(body{:,i})]; %#ok<AGROW>
        end
    end
    
    % delete old things
    DB('QuantTrading').runSql(['delete from axioma.' tblname ' where ' clause(5:end)]);

    if isa(xtsdata, 'xts') % general case
        body = repmat(body, size(xtsdata,2),1);
        data = squeeze(xtsdata);  % we want to remove first dim
        if isa(data,'xts')        % but data still be a myfints if 2nd dim is also 1
            data = fts2mat(data); % so we do this
        end
        if ~iscell(data)
            data = num2cell(data);
        end
        body = [body fieldnames(xtsdata,1,1) data];
        flds = [flds; idfld; fieldnames(xtsdata,1,2)];
    else  % xtsdata must be a structure. only for writing SolutionTS table
        flds = [flds; fieldnames(xtsdata)];
        body = [body struct2cell(xtsdata)'];
    end
    
    dbBulkInsert('QuantTrading', ['axioma.' tblname], flds, body);
end

function cellarr = checkcell(cellarr)
    if ~iscell(cellarr.id)
        fn = fieldnames(cellarr);
        for i=1:length(fn)
            cellarr.(fn{i}) = {cellarr.(fn{i})};
        end
    end
end

