classdef AXOptimization < handle
    properties (Constant, GetAccess = private)
        singleton = AXOptimization;
        Account   = {'ACCOUNT', 'ACCOUNT.LONG', 'ACCOUNT.SHORT'};
        Alpha     = {'REBALANCING.ALPHA_GROUP'};
        Benchmark = {'REBALANCING.BENCHMARK'};
        Attribute = {'REBALANCING.PRICE_GROUP', 'REBALANCING.ROUND_LOT_GROUP', 'PREEMPTIVE_SELLOUT'};
        AssetSet  = {'MASTER', 'LOCAL_UNIVERSE', 'COMPOSITE', 'NON-CASH ASSETS'}
        RiskModel = {'REBALANCING.RISK_MODEL'};
        TCModel   = {'REBALANCING.COST_MODEL'};
    end
    
    properties
        date = NaN;
        ws = [];  % workspace it owns, initialized when axioma started
    end
    
    properties (Dependent)
        secids
        javadate
        dates
    end
    
    properties (Access = private)
        dataset         % ref to an AXDataSet
        strategy = [];  % copy of current AXStrategy obj
        rebal = [];     % copy of current AXRebalancing obj
        
        strategies % ref to a container of AXStrategy array (each date may have multiple AXStrategy)
        rebals     % ref to a container of AXRebalancing (each date got an AXRebalacing)
    end
    
    methods
        function o = AXOptimization(dataset, strategy, rebal)
            if isa(AXOptimization.singleton, 'AXOptimization')
                o = AXOptimization.singleton;
            end
            if nargin ~= 0
                FTSASSERT(isa(dataset,'AXDataSet'), [inputname(1) 'must be type of AXDataSet']);
                o.dataset = dataset;
                FTSASSERT(isa(strategy,'containers.Map') | isa(strategy,'AXStrategy'), ...
                    [inputname(2) 'must be either an AXStrategy or container of AXStrategy']);
                o.strategies = strategy;
                FTSASSERT(isa(rebal,'containers.Map') | isa(rebal,'AXRebalancing'), ...
                    [inputname(3) 'must be either an AXRebalancing or container of AXRebalancing']);
                o.rebals = rebal;
            end
        end
        
        function sids = get.secids(o)
            if isa(o.dataset, 'AXDataSet')
                sids = o.dataset.getUniverse(o.date);
            else
                sids = {};
            end
        end
        
        function jdate = get.javadate(o)
            sdf = java.text.SimpleDateFormat('yyyy-mm-dd');
            jdate = sdf.parse(datestr(o.date,'yyyy-mm-dd'));
        end
        
        function dts = get.dates(o)
            dts = o.dataset.dates;
        end
        
        function d = getData(o, id)
            set = [o.Account o.Alpha o.Benchmark o.Attribute o.AssetSet o.RiskModel o.TCModel];
            if ~ismember(upper(id),set)
                d = o.dataset(id);
            else
                d = [];
            end
        end
            
        function st = getSelectionType(o, id)
            id = upper(id);
            if ismember(id, [o.secids;{'CASH'}])
                st = AXSelection.ASSET;
            elseif ismember(id, [o.Account o.Alpha o.Benchmark o.Attribute])
                st = AXSelection.GROUP;
            elseif ismember(id, o.AssetSet)
                st = AXSelection.SET;
            else
                [token,riskmg] = strtok(id, '.');
                if strcmpi(riskmg(2:end),'COMMON FACTORS')
                    st = AXSelection.METAGROUP;
                elseif strcmpi(token,'SHORTBAN')
                    st = AXSelection.GROUP;
                else
                    st = getSelectionTypeLocally(o.dataset, id);
                end
            end
        end
        
        function results = run(o, dates, outputpath)
            addAxiomaJavaPath;
            results = containers.Map('KeyType', 'double', 'ValueType', 'any');
            TRACE('Initializing AXIOMA ... ');
            com.axiomainc.portfolioprecision.AxiomaPortfolioAPI.setUp();
            TRACE('done\n');
            originalAccount = [];
            ban = configShortSellBan(o,dates); 
            
            for t = 1:length(dates)
                o.date = dates(t);
                setCurrentRebalancing(o);
                setCurrentStrategy(o);
                tstr = datestr(o.date,'yyyy-mm-dd');
                TRACE('\n%d/%d %s\n', t, length(dates), tstr);
                hasSolution = false;
                if ~isempty(ban), export(ban.group); end

                try
                    % Create workspace
                    TRACE('    Creating workspace ... ');
                    o.ws = com.axiomainc.portfolioprecision.Workspace('Workspace', '', o.javadate);
                    TRACE('Success\n');
                    o.ws.setReferenceCountOn(false);
                    cash = com.axiomainc.portfolioprecision.SimpleAsset(o.ws,'CASH','CASH');
                    cash.setAsCash();
                    com.axiomainc.portfolioprecision.Benchmark(o.ws, 'CASHBM', ...
                     com.axiomainc.portfolioprecision.Unit.valueOf(char(Unit.PERCENT)), ...
                     {'CASH'}, 100);

                    % Export everything to workspace
                    export(o.dataset);
                    if ~o.dataset.isLive, export(preemptiveAttr(o)); end
                    for i = 1:length(o.strategy)
                        if ~o.dataset.isLive
                            o.strategy(i).constraints = [o.strategy(i).constraints; {preemptiveConstraint(o)}];
                            o.strategy(i).excluded = [o.strategy(i).excluded ; {'PREEMPTIVE_SELLOUT'}];
                        end
                        if ~isempty(ban)
                            if ~isempty(ban.constraints{t})
                                o.strategy(i).constraints = [o.strategy(i).constraints; ban.constraints(t)];
                            end
                        end
                        export(o.strategy(i));
                    end
                    export(o.rebal);

                    % Solve the problem
                    reb = o.ws.getRebalancing(o.rebal.id);
                    solutions = [];  % record all solutions for this rebalancing
                    for i = 1:length(o.strategy)
                        sol.solts.starttime = datestr(now, 'yyyy-mm-dd HH:MM:ss');
                        TRACE(['    Solving the problem with strategy ' o.strategy(i).id '...']);
                        reb.setStrategy(o.ws.getStrategy(o.strategy(i).id));
                        rebalstatus = reb.solve();
                        rebalstatus = char(rebalstatus.toString());
                        TRACE([regexprep(rebalstatus, '[A-Z]', ' $0') '\n']);

                        if strcmpi(rebalstatus, 'SolutionFound') || strcmpi(rebalstatus, 'RelaxedSolutionFound')
                            if strcmpi(rebalstatus, 'SolutionFound')
                                sol.solts.hasSolution = 1;
                            else
                                sol.solts.hasSolution = 2;
                            end
                            hasSolution = true;
                            TRACE('    Generating Analytical Results ... ');
                            [sol.pfinit, sol.pffinal, sol.trd, sol.summary] = getSolution(o);
                            sol.vios = getConstraintViolations(o);
                            TRACE('done\n');
                        else
                            sol.solts.hasSolution = 0;
                        end
                        sol.solts.completetime = datestr(now, 'yyyy-mm-dd HH:MM:ss');
                        sol.frontierid = o.rebal.DBID;           % coupled with DB but seemed harmless
                        sol.rebalanceid = o.strategy(i).DBID;    % coupled with DB but seemed harmless
                        solutions = [solutions; sol]; %#ok<AGROW>
                    end
                    
                    results(o.date) = solutions;

                    %% Save Workspace
                    outfile = [outputpath tstr '.xml'];
                    if exist(outfile,'file')
                        fileattrib(outfile,'+w');
                    end
                    com.axiomainc.portfolioprecision.io.xml.WorkspaceWriter.write(o.ws, outfile);
                    fileattrib(outfile,'-w'); %Lock the workspace automatically

                catch e
                    TRACE('\n%s\n', getReport(e));
                end

                if isa(o.ws, 'com.axiomainc.portfolioprecision.Workspace')
                    TRACE('    Tearing down workspace ... ');
                    o.ws.setReferenceCountOn(true);
                    o.ws.destroy();
                    TRACE('done\n');
                end
                
                if hasSolution
                    bestSolIdx = 1;
                    newaccount = solutions(bestSolIdx).pffinal(:,:,'share');
                    newaccount(:, fts2mat(newaccount)==0) = [];
                    newaccount.unit = Unit.SHARES;
                    if isempty(originalAccount)
                        originalAccount = o.dataset(o.rebal.accountId);
                    end
                    o.dataset(o.rebal.accountId) = AXAttr(o.rebal.accountId, newaccount, 'ACCOUNT');
                else
                    break;
                end
            end
            
            if ~isempty(originalAccount)
                o.dataset(o.rebal.accountId) = originalAccount;
            end
            
            TRACE('\nTearing down AXIOMA ... ');
            com.axiomainc.portfolioprecision.AxiomaPortfolioAPI.tearDown();
            o.ws = [];
            o.date = NaN;
            o.rebal = [];
            o.strategy = [];
            TRACE('done\n');
        end
        
        function results = runsmart(o, dates, outputpath)
            addAxiomaJavaPath;
            results = containers.Map('KeyType', 'double', 'ValueType', 'any');
            TRACE('Initializing AXIOMA ... ');
            com.axiomainc.portfolioprecision.AxiomaPortfolioAPI.setUp();
            TRACE('done\n');
            originalAccount = [];
            ban = configShortSellBan(o,dates); 
            
            for t = 1:length(dates)
                o.date = dates(t);
                setCurrentRebalancing(o);
                setCurrentStrategy(o);
                tstr = datestr(o.date,'yyyy-mm-dd');
                TRACE('\n%d/%d %s\n', t, length(dates), tstr);
                hasSolution = false;

                try
                    % Create workspace
                    TRACE('    Creating workspace ... ');
                    o.ws = com.axiomainc.portfolioprecision.Workspace('Workspace', '', o.javadate);
                    TRACE('Success\n');
                    o.ws.setReferenceCountOn(false);
                    cash = com.axiomainc.portfolioprecision.SimpleAsset(o.ws,'CASH','CASH');
                    cash.setAsCash();
                    com.axiomainc.portfolioprecision.Benchmark(o.ws, 'CASHBM', ...
                     com.axiomainc.portfolioprecision.Unit.valueOf(char(Unit.PERCENT)), ...
                     {'CASH'}, 100);

                    % Export everything to workspace
                    export(o.dataset);
                    if ~o.dataset.isLive, export(preemptiveAttr(o)); end
                    if ~isempty(ban), export(ban.group); end
                    for i = 1:length(o.strategy)
                        if ~o.dataset.isLive
                            o.strategy(i).constraints = [o.strategy(i).constraints; {preemptiveConstraint(o)}];
                            o.strategy(i).excluded = [o.strategy(i).excluded ; {'PREEMPTIVE_SELLOUT'}];
                        end
                        if ~isempty(ban)
                            if ~isempty(ban.constraints{t})
                                o.strategy(i).constraints = [o.strategy(i).constraints; ban.constraints(t)];
                            end
                        end
                        export(o.strategy(i));
                    end
                    export(o.rebal);

                    % Solve the problem
                    reb = o.ws.getRebalancing(o.rebal.id);
                    solutions = [];  % record all solutions for this rebalancing
                    for i = 1:length(o.strategy)
                        sol.solts.starttime = datestr(now, 'yyyy-mm-dd HH:MM:ss');
                        TRACE(['    Solving the problem with strategy ' o.strategy(i).id '...']);
                        
                        % Find the constraint hierarchy (if any)
                        str = o.ws.getStrategy(o.strategy(i).id);
                        conshier = str.getConstraintHierarchy();
                        it = conshier.getConstraints.iterator();
                        k=1;
                        constr = cell(1,conshier.getConstraints.size());
                        priority = zeros(1,conshier.getConstraints.size());
                        while it.hasNext()
                            cons = it.next();
                            constr{k} = char(cons.getIdentity());
                            priority(k) = conshier.getPriority(cons);
                            k = k+1;
                        end
                        if ~isempty(constr)
                            [priority, idx] = sort(priority,'descend');
                            constr = constr(idx);
                        end
                        
                        k = 1;
                        while hasSolution == false && k <= 1 + length(priority)
                            reb.setStrategy(str);
                            rebalstatus = reb.solve();
                            rebalstatus = char(rebalstatus.toString());
                            TRACE([regexprep(rebalstatus, '[A-Z]', ' $0') '\n']);
                            
                            if strcmpi(rebalstatus, 'SolutionFound') || strcmpi(rebalstatus, 'RelaxedSolutionFound')
                                if strcmpi(rebalstatus, 'SolutionFound')
                                    sol.solts.hasSolution = 1;
                                else
                                    sol.solts.hasSolution = 2;
                                end
                                hasSolution = true;
                                TRACE('    Generating Analytical Results ... ');
                                [sol.pfinit, sol.pffinal, sol.trd, sol.summary] = getSolution(o);
                                sol.vios = getConstraintViolations(o);
                                TRACE('done\n');
                            elseif k <= length(priority) && priority(k) > 0
                                TRACE(['        Discarding Constraint ' constr{k} ' ... ']);
                                str.getConstraint(constr{k}).setEnabled(false); 
                            else
                                sol.solts.hasSolution = 0;
                            end
                            k = k + 1;
                        end
                        sol.solts.completetime = datestr(now, 'yyyy-mm-dd HH:MM:ss');
                        sol.frontierid = o.rebal.DBID;           % coupled with DB but seemed harmless
                        sol.rebalanceid = o.strategy(i).DBID;    % coupled with DB but seemed harmless
                        solutions = [solutions; sol]; %#ok<AGROW>
                    end
                    
                    results(o.date) = solutions;

                    %% Save Workspace
                    if exist('outputpath','var')
                        outfile = [outputpath tstr '.xml'];
                        if exist(outfile,'file')
                            fileattrib(outfile,'+w');
                        end
                        com.axiomainc.portfolioprecision.io.xml.WorkspaceWriter.write(o.ws, outfile);
                        fileattrib(outfile,'-w'); %Lock the workspace automatically
                    end

                catch e
                    outfile = ['FAIL_' tstr '.xml'];
                    if exist(outfile,'file')
                        fileattrib(outfile,'+w');
                    end
                    com.axiomainc.portfolioprecision.io.xml.WorkspaceWriter.write(o.ws, outfile);
                    TRACE('\n%s\n', getReport(e));                    
                end

                if isa(o.ws, 'com.axiomainc.portfolioprecision.Workspace')
                    TRACE('    Tearing down workspace ... ');
                    o.ws.setReferenceCountOn(true);
                    o.ws.destroy();
                    TRACE('done\n');
                end
                
                if hasSolution
                    bestSolIdx = 1;
                    newaccount = solutions(bestSolIdx).pffinal(:,:,'share');
                    newaccount(:, fts2mat(newaccount)==0) = [];
                    newaccount.unit = Unit.SHARES;
                    if isempty(originalAccount)
                        originalAccount = o.dataset(o.rebal.accountId);
                    end
                    o.dataset(o.rebal.accountId) = AXAttr(o.rebal.accountId, newaccount, 'ACCOUNT');
                else
                    break;
                end
            end
            
            if ~isempty(originalAccount)
                o.dataset(o.rebal.accountId) = originalAccount;
            end
            
            TRACE('\nTearing down AXIOMA ... ');
            com.axiomainc.portfolioprecision.AxiomaPortfolioAPI.tearDown();
            o.ws = [];
            o.date = NaN;
            o.rebal = [];
            o.strategy = [];
            TRACE('done\n');
        end
        
        function stat = report(o, results, fname, rebaldates, str)
            if ~exist('rebaldates','var')
                rebaldates = o.dates;
            end
            if isa(o.rebals, 'AXRebalancing')
                reb = o.rebals;
            else
                reb = o.rebals(o.dates(1));
            end
            if ~exist('str','var')
                str = [];
            end
            rep = Report(o.dataset, reb, results, fname, rebaldates, str);
            stat = rep.run;
        end
   end % of methods
    
    methods (Access = private)
        function setCurrentStrategy(o)
            if isa(o.strategies, 'AXStrategy')
                o.strategy = o.strategies;
            else
                o.strategy = o.strategies(o.date);
                if iscell(o.strategy) && numel(o.strategy) == 1
                    o.strategy = o.strategy{:};
                end
            end
        end
        
        function setCurrentRebalancing(o)
            if isa(o.rebals, 'AXRebalancing')
                o.rebal = o.rebals;
            else
                o.rebal = o.rebals(o.date);
                if iscell(o.rebal) && numel(o.rebal) == 1
                    o.rebal = o.rebal{:};
                end
            end
            trimUniverse(o.dataset, ~isnan(o.dataset(o.rebal.priceId)));
        end

        function a = preemptiveAttr(o)
            dates = o.dataset.dates;
            price = leadts(aligndates(o.dataset(o.rebal.priceId), dates, 'calcmethod', 'exact'), 1, NaN);
            price(end,:) = 0;  % not deal with the last period b.c. no forward data
            grp = price;
            grp(:,:) = NaN;
            grp(isnan(price)) = 1;
            a = AXAttr('PREEMPTIVE_SELLOUT', grp, 'GROUP');
        end

        function c = preemptiveConstraint(~)
            c = AXConstraint('PREEMPTIVE_LIMITHOLDING', 'LimitHoldingConstraint');
            c.SCOPE = 'ASSET';
            c.UNIT  = Unit.SHARES;
            c.MAX   = 0;
            c.MIN   = 0;
            c.selection = 'PREEMPTIVE_SELLOUT';
        end

        function ban = configShortSellBan(o,dates)
            % Returns a structure with the following fields:
            % ban.group - an AXAttr object
            % ban.constraints - a cell array of constraints with length numel(dates)
            ban ={};            
            dnum = dates;
            v = values(o.strategies);
            if (length(v) == 1), v = v{:}; end
            if all(cellfun(@(c) c.isAllowShorting, v))
                dates = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},dates);
                datelist = sprintf(',%s',dates{:});
                aggidlist = sprintf(',%s',o.dataset.aggid{:});
                try
                    TRACE('Preparing Constraints for Short Selling Ban ... ');
                    uni = o.dataset.getUniverse;
                    idlist = sprintf(',%s',uni{:,1});
                    ret = DB('QuantTrading').runSql('axapi.GetExchangeGICS',idlist(2:end),datelist(2:end),14,1);
                    xts = mat2xts(datenum(ret.date),ret.value,ret.id);
                    xts.unit = Unit.TEXT;
                    ban.group = AXAttr('SHORTBAN', xts, 'METAGROUP');
                catch e
                    if ~strcmp(e.identifier,'LOADDATA:NODATA')
                        rethrow(e);
                    end
                end            
                if ~isempty(ban)
                    ban.constraints = cell(numel(dates),1);
                    try
                        banData = DB('QuantTrading').runSql('dbo.GetShortBanTS',aggidlist(2:end),datelist(2:end));
                    catch e
                        if ~strcmp(e.identifier,'LOADDATA:NODATA')
                            rethrow(e);
                        end
                        banData = {};
                    end
                    if ~isempty(banData)
                        bdates = datenum(banData.Date);
                        bgroup = banData.BanGroup;
                        if ~iscell(bgroup)
                            bgroup = {bgroup};
                        end
                        btype = banData.BanType;
                        if ~iscell(btype)
                            btype = {btype};
                        end
                        for dt=1:numel(dnum)
                            idx = bdates == dnum(dt);
                            c = cell(2,1);
                            i = 1;
                            if nansum(idx) > 0
                                selection = bgroup(idx);
                                ctype = btype(idx);
                                tidx = strcmpi(ctype,'trade');                                
                                if nansum(tidx) > 0
                                    % Create Limit Trade Constraint
                                    c{i} = AXConstraint('SHORTBAN_TRADE', 'LimitTradeConstraint');
                                    c{i}.SCOPE = 'ASSET';
                                    c{i}.UNIT  = Unit.PERCENT;
                                    c{i}.MAX   = 0;
                                    c{i}.MIN   = 0;
                                    c{i}.selection = cellfun(@(c) {['SHORTBAN.' c]},selection(tidx));
                                    i = i + 1;
                                end
                                hidx = strcmpi(ctype,'holding');
                                if nansum(hidx) > 0
                                    % Create Limit Holding Constraint   
                                    c{i} = AXConstraint('SHORTBAN_HOLDING', 'LimitHoldingConstraint');
                                    c{i}.SCOPE = 'ASSET';
                                    c{i}.UNIT  = Unit.PERCENT;
                                    c{i}.MAX   = 0;
                                    c{i}.MIN   = 0;
                                    c{i}.selection = cellfun(@(c) {['SHORTBAN.' c]},selection(hidx));
                                    i = i + 1;
                                end
                            end                               
                            if i <= 2
                                c(2) = [];
                            end
                            ban.constraints(dt) = c;
                        end
                    end
                    TRACE('done\n');
                end
            end
        end
        
        function [pfinit, pffinal, trdxts, summary] = getSolution(o)
            solution = o.ws.getRebalancing(o.rebal.id).getSolution();
            solution.evaluate();
            
            price = solution.getRebalancingBase().getPriceGroup();
            analyzer = com.axiomainc.portfolioprecision.Analytics(price);

            init  = solution.getInitialHoldings();
            final = solution.getFinalHoldings();
            if ~isempty(o.rebal.prevalphaId)
                [pfinit,  initsummary] = getPFDetails(o, init, o.rebal.prevalphaId);
            else
                [pfinit,  initsummary] = getPFDetails(o, init, o.rebal.alphaId);
            end
            [pffinal, finalsummary] = getPFDetails(o, final, o.rebal.alphaId);

            pfinit(:,:,{'impliedAlpha', 'impliedBeta', 'activeHoldingLiquid'}) = [];

            tcm = solution.getRebalancingBase().getTransactionCostModel();
            
            finalsummary.tcost    = analyzer.computeTransactionCost(tcm,init,final);
            finalsummary.tcost_est = finalsummary.tcost;
            finalsummary.buyto    = analyzer.computeTurnoverBuy(init,final);
            finalsummary.sellto   = analyzer.computeTurnoverSell(init,final);
            finalsummary.turnover = analyzer.computeTurnover(init,final);
            finalsummary.buytopct    = finalsummary.buyto ./ finalsummary.value;
            finalsummary.selltopct   = finalsummary.sellto ./ finalsummary.value;
            finalsummary.turnoverpct = finalsummary.turnover ./ finalsummary.value;
            finalsummary.cashflow    = finalsummary.buyto - finalsummary.sellto;

            % Init trdxts (for SolutionTrade)
            flds = {'initquantity', 'finalquantity', 'quantity', 'tradeprice', 'tradevalue', 'tradevaluepct', 'transactioncost'};
            ta = solution.getTradedAssets();
            N = ta.size;
            data = nan(1, N, length(flds));
            ta = toArray(ta);
            secid = arrayfun(@(x){char(getIdentity(x))}, ta);

            trdxts = xts(o.date, data, secid, flds);

            trdxts(1,:,'initquantity')  = pfinit(1,secid,'share');
            trdxts(1,:,'finalquantity') = pffinal(1,secid,'share');
            trdxts(1,:,'quantity')   = trdxts(1,:,'finalquantity') - trdxts(1,:,'initquantity');
            trdxts(1,:,'tradeprice') = pffinal(1,secid,'price');
            for i = 1:N
                trdxts(1,i,'transactioncost') = tcm.getTransactionCost(...
                    ta(i), fts2mat(trdxts(1,i,'quantity')), fts2mat(trdxts(1,i,'tradeprice')));
            end
            trdxts(:,:,'tradevaluepct') = trdxts(:,:,'quantity') * trdxts(:,:,'tradeprice') ./ finalsummary.value;
            trdxts(:,:,'quantity') = round(fts2mat(trdxts(:,:,'quantity')));  % revisit tradeshares
            trdxts(:,fts2mat(trdxts(:,:,'quantity')==0),:) = [];  % !!! only valid when time dim is of length 1
            trdxts(:,:,'tradevalue') = trdxts(:,:,'quantity') * trdxts(:,:,'tradeprice');
%             volume = getExport(o.dataset(o.rebal.volumeId));
%             trdxts(:,:,'tradelq') = trdxts(:,:,'tradevalue') ./ volume(:,secid);

            if ~isempty(o.rebal.rcmodelId)
                rcm = o.dataset(o.rebal.rcmodelId);
                tv = trdxts(1,:,'quantity').*trdxts(1,:,'tradeprice');
                if ismember({'CASH'},fieldnames(tv,1))
                    tv(:,'CASH') = [];
                end
                arrival = aligndata(rcm.arrival,tv);
                finalsummary.arrival = nansum(bsxfun(@times,tv,arrival),2);
                marketimpact = aligndata(rcm.marketimpact,tv);
                finalsummary.marketimpact = nansum(bsxfun(@times,tv,marketimpact),2);
                vwapspread = aligndata(rcm.vwapspread,tv);
                finalsummary.vwapspread = nansum(bsxfun(@times,abs(tv),vwapspread),2);
                commission = aligndata(rcm.commission,tv);
                finalsummary.commission = nansum(bsxfun(@times,abs(tv),commission),2);
                fee = aligndata(rcm.fee,tv);
                finalsummary.fee = nansum(bsxfun(@times,abs(tv),fee),2);
                fv = trdxts(1,:,'finalquantity').*trdxts(1,:,'tradeprice');
                if ismember({'CASH'},fieldnames(fv,1))
                    fv(:,'CASH') = [];
                end
                fv(fv > 0) = 0;
                fv = -fv;
                borrowcost = aligndata(rcm.borrowcost,fv);
                finalsummary.borrowcost_ann = nansum(bsxfun(@times,fv,borrowcost),2);                
                finalsummary.tcost = finalsummary.arrival + finalsummary.marketimpact + finalsummary.vwapspread + finalsummary.commission + finalsummary.fee;
            else
                finalsummary.arrival = 0;
                finalsummary.marketimpact = 0;
                finalsummary.vwapspread = 0;
                finalsummary.commission = 0; 
                finalsummary.fee = 0;
                finalsummary.borrowcost_ann = 0;
            end

            curralpha = getExport(o.dataset(o.rebal.alphaId));
            if isempty(o.rebal.prevalphaId)
                prevalpha = curralpha;
            else
                prevalpha = getExport(o.dataset(o.rebal.prevalphaId));
            end
            deltaAlpha = bsxfun(@minus, curralpha, prevalpha);
            [deltaAlpha, trdweight_] = alignfields(deltaAlpha, trdxts(:,:,'tradevaluepct'));
            finalsummary.tradeTC   = fts2mat(cscorr(deltaAlpha, trdweight_));
            finalsummary.buycount  = nansum(trdxts(:,:,'quantity') >= 0, 2);
            finalsummary.sellcount = nansum(trdxts(:,:,'quantity') < 0, 2);
            finalsummary.tradecount = numel(secid);
            
            trdxts = cat(3, uniftsfun(trdxts, @(x) num2cell(x)), transType, tradeType);
            trdxts(:,:,{'initquantity','finalquantity'}) = [];
            
            summary = struct2xts(struct('initial', initsummary, 'final', finalsummary), o.date);
            summary = uniftsfun(summary, @(x) cell2mat(x));
            summary = uniftsfun(summary, @(x)cat(3,x,x(:,:,2)-x(:,:,1)), {'',{'initial','final','delta'}});
            
            function tt = transType
                buyl  = trdxts(:,:,'finalquantity') >= 0 & trdxts(:,:,'quantity') > 0;
                selll = trdxts(:,:,'finalquantity') >= 0 & trdxts(:,:,'quantity') < 0;
                buys  = trdxts(:,:,'finalquantity') < 0 & trdxts(:,:,'quantity') > 0;
                sells = trdxts(:,:,'finalquantity') < 0 & trdxts(:,:,'quantity') < 0;
                sz = size(trdxts);
                tt = myfints(trdxts.dates, cell(sz(1:2)), fieldnames(trdxts,1,1));
                tt(:,:) = {''};
                tt(buyl)  = {'BUYL'};
                tt(selll) = {'SELLL'};
                tt(buys)  = {'BUYS'};
                tt(sells) = {'SELLS'};
                tt.desc = 'transtype';
            end
            
            function tt = tradeType
                buynew   = trdxts(:,:,'initquantity') == 0 & trdxts(:,:,'quantity') > 0;
                buysome  = trdxts(:,:,'initquantity') > 0 & trdxts(:,:,'quantity') > 0;
                sellsome = trdxts(:,:,'initquantity') > 0 & trdxts(:,:,'quantity') < 0;
                sellall  = trdxts(:,:,'initquantity') > 0 & trdxts(:,:,'finalquantity') == 0;
                sz = size(trdxts);
                tt = myfints(trdxts.dates, cell(sz(1:2)), fieldnames(trdxts,1,1));
                tt(:,:) = {''};
                tt(buynew)  = {'BUYNEW'};
                tt(buysome) = {'BUYSOME'};
                tt(sellsome) = {'SELLSOME'};
                tt(sellall)  = {'SELLALL'};
                tt.desc = 'tradetype';
            end
        end
        
        function [pf, summary] = getPFDetails(o, portfolio, alphaid)
            solution = o.ws.getRebalancing(o.rebal.id).getSolution();
            price = solution.getRebalancingBase().getPriceGroup();
            analyzer = com.axiomainc.portfolioprecision.Analytics(price);

            summary.value = portfolio.getTotalValue(price);
            summary.longvalue  = portfolio.getLongValue(price);
            summary.shortvalue = portfolio.getShortValue(price);
            summary.longcashvalue = portfolio.getLongCashValue(price);
            summary.shortcashvalue = portfolio.getShortCashValue(price);
            if summary.shortvalue == 0
                summary.LSratio = NaN;
            else
                summary.LSratio = summary.longvalue ./ summary.shortvalue;
            end
            summary.count = portfolio.getNameCount();
            
            secid = cell(1, summary.count);
            pfshare = nan(1, summary.count);
            i = 1;
            it = portfolio.getAssets().iterator();
            while it.hasNext()
                asset = it.next();
                secid{i} = char(asset.getIdentity());
                pfshare(i) = portfolio.getShares(asset);
                i = i+1;
            end
            summary.longcount = portfolio.getLongHoldings().getNameCount();
            summary.shortcount = portfolio.getShortHoldings().getNameCount();
            summary.cashcount = portfolio.getCashNameCount();
                        
            pf.bmweight = getExport(o.dataset(o.rebal.benchmarkId)) ./ 100;
            % add 0 weight of cash into benchmark
            if ~ismember({'CASH'},fieldnames(pf.bmweight,1))
                pf.bmweight = padfield(pf.bmweight,[fieldnames(pf.bmweight,1);{'CASH'}],0);
            end
            bmflds = fieldnames(pf.bmweight,1);
            pf.price = padfield(getExport(o.dataset(o.rebal.priceId)), bmflds, NaN);

            if summary.longcount + summary.shortcount == 0
                pf.share = myfints(o.date, zeros(1, numel(bmflds)), bmflds);
            else
                pf.share = padfield(myfints(o.date, pfshare, secid), bmflds, 0);
            end
            
            pf.pfweight = pf.share .* pf.price ./ summary.value;

            pf.actweight = pf.pfweight - pf.bmweight;   % active weight
            
            volume = getExport(o.dataset(o.rebal.volumeId));
            volume = padfield(volume, bmflds, 0);
            if isequal(volume.unit,Unit.SHARES)
                volume = volume .* pf.price;
            end
            
            if ~all(cellfun(@(c) c.isAllowShorting, values(o.strategies)))
                pf.activeHoldingLiquid = pf.actweight .* summary.value ./ volume; % active holding liquidity
            else
                pf.activeHoldingLiquid = pf.pfweight .* summary.value ./ volume; % absolute holding liquidity
            end
            
            %% Calculate summary analytics and store in structure
            value = summary.value;
            benchmark = solution.getRebalancingBase().getBenchmark();
            riskmodel = solution.getRebalancingBase().getRiskModel();
            bench = benchmark.getAsHoldings(value);
            masterset = o.ws.getMasterSet;
            impliedAlpha = analyzer.computeImpliedAlpha(riskmodel, portfolio, masterset);
            impliedBeta  = analyzer.computeImpliedBeta(riskmodel, benchmark, masterset);
            [pf.impliedAlpha, pf.impliedBeta] = javaset2xts(o.date, impliedAlpha, impliedBeta);
            
            impliedBeta = com.axiomainc.portfolioprecision.SimpleGroup(o.ws,'ImpliedBeta',...
 			    com.axiomainc.portfolioprecision.Unit.valueOf('NUMBER'), impliedBeta);
            summary.activerisk   = analyzer.computeActiveTotalRisk(riskmodel,portfolio,benchmark,value) / value;
            summary.totalrisk_pf = analyzer.computeTotalRisk(riskmodel,portfolio) / value;
            summary.totalrisk_bm = analyzer.computeTotalRisk(riskmodel,bench) / value;
            beta = o.ws.getGroup(o.rebal.betaId);
            summary.beta   = analyzer.computeExpectedReturn(portfolio,beta) / value;
            summary.activebeta   = analyzer.computeExpectedReturn(portfolio,beta) / value ...
                                 - analyzer.computeExpectedReturn(bench,beta) / value;
            summary.impliedbeta = analyzer.computeExpectedReturn(portfolio,impliedBeta) / value;
            summary.factorrisk  = analyzer.computeFactorRisk(riskmodel,portfolio) / value;
            summary.specrisk    = analyzer.computeSpecificRisk(riskmodel,portfolio) / value;
            summary.actfactorrisk = analyzer.computeActiveFactorRisk(riskmodel,portfolio,benchmark,value) / value;
            summary.actspecrisk   = analyzer.computeActiveSpecificRisk(riskmodel,portfolio,benchmark,value) / value;
            summary.VAR = analyzer.computeValueAtRisk(riskmodel,portfolio,benchmark,value,0.05) / value;

            summary.actshares = nansum(abs(pf.actweight),2) / 2.0;   % active shares, nothing to do with analyzer
            summary.leverage = nansum(abs(pf.pfweight),2);
            
            if ~isempty(alphaid)
                alpha = o.ws.getGroup(alphaid);
                alphafactorExp = analyzer.computeAlphaFactor(riskmodel, alpha, benchmark.getAssets, true);
                pf.alphafactorExposure = javaset2xts(o.date, alphafactorExp);
                summary.expectedreturn = analyzer.computeExpectedReturn(portfolio,alpha) / value;
                if ~all(cellfun(@(c) c.isAllowShorting, values(o.strategies)))
                    summary.axiomaTC = analyzer.computeTransferCoefficient(riskmodel,alpha,portfolio,benchmark,value);
                else
                    try
                        summary.axiomaTC = analyzer.computeTransferCoefficient(riskmodel,alpha,portfolio,o.ws.getGroup('CASHBM'),value);
                    catch e
                        if strcmpi(e.identifier,'MATLAB:Java:GenericException')
                            summary.axiomaTC = 0;
                        end
                    end
                end
                pf.alpha = padfield(getExport(o.dataset(alphaid)), bmflds, NaN);
                hrlist = ~xor(fts2mat(pf.alpha) >= nanmean(pf.alpha,2), fts2mat(pf.actweight) >= 0);
                hrlist(isnan(fts2mat(pf.alpha))) = [];                 % hrlist is vector
                summary.alphahitrate = nansum(hrlist,2) / numel(hrlist);% alpha hit rate
                if ~all(cellfun(@(c) c.isAllowShorting, values(o.strategies)))
                    summary.linearTC  = fts2mat(csrankcorr(pf.alpha, pf.actweight)); % linear transfer coefficient
                else
                    summary.linearTC  = fts2mat(csrankcorr(pf.alpha, pf.pfweight)); % linear transfer coefficient
                end
            end

            %% Clean Up
            impliedBeta.destroy();
           
            pf = struct2xts(pf);
        end
        
        function vios = getConstraintViolations(o)
            solution = o.ws.getRebalancing(o.rebal.id).getSolution();
            clist = o.ws.getRebalancing(o.rebal.id).getStrategy().getConstraints();
            % Loop each constraint and find out the violations
            flds = {'iv', 'fv', 'b_min', 'b_max', 'i_vio', 'f_vio'};
            tblflds = {'initialvalue', 'finalvalue', 'minbound', 'maxbound', 'initialviolation', 'finalviolation'};
            cit = clist.iterator();
            while(cit.hasNext()) 
                cons = cit.next(); % Get API Constraint Class
                cv = solution.getConstraintValues(cons); %API Constraint Values Class
                if cv.size() == 0
                    continue;  % nothing can be done
                end
                cname = char(cons.getIdentity());
                if ~isempty(cons.getProperties().getUnit())
                    unit = char(cons.getProperties().getUnit().toString());
                else
                    unit = 'NUMBER';
                end
%                 cvxts = xts(o.date, nan(1, cv.size(),length(flds)), '', flds);
                cvxts = nan(1, cv.size(), length(flds));
                namelist = cell(cv.size(),1);
                i = 1;
                vit = cv.iterator();
                while(vit.hasNext())
                    j = vit.next(); %Get the asset/selection/member/aggregate
                    vid = j.getEntry().getIdentity();
                    namelist{i} = char(vid);
                    if ~isempty(j.getWeight())
                        wgt = j.getWeight();
                    else
                        wgt = 1;
                    end
                    cvxts(1,i,1) = j.getInitialValue()/wgt; %iv
                    cvxts(1,i,2) = j.getFinalValue()/wgt; %fv
                    if j.hasMinBound()
                        cvxts(1,i,3) = j.getMinBound()/wgt; %b_min
                    end
                    if j.hasMaxBound()
                        cvxts(1,i,4) = j.getMaxBound()/wgt; %b_max
                    end
                    i=i+1;
                end
                cvxts = xts(o.date, cvxts, '', flds);
                
                cvxts = chfield(cvxts, fieldnames(cvxts,1,1), namelist, 1);
                switch Unit.(unit)
                    case Unit.SHARES
                        price = getExport(o.dataset(o.rebal.priceId));
                        cvxts(1,:,:) = bsxfun(@rdivide, cvxts(1,:,:), price(1,namelist));
                    case Unit.PERCENT
                        if strcmp(class(cons),'com.axiomainc.portfolioprecision.optimization.constraints.LimitWeightedAvgConstraint')
                            refsize = 1;
                        else
                            refsize = o.ws.getRebalancing(o.rebal.id).getReferenceSize();
                        end
                        cvxts(1,:,:) = cvxts(1,:,:) ./ refsize;
                end
                
                % Find min bound violation if any
                cvxts(:,:,'i_vio') = cvxts(:,:,'b_min') - cvxts(:,:,'iv');
                cvxts(:,:,'f_vio') = cvxts(:,:,'b_min') - cvxts(:,:,'fv');
                cvxts(:,:,'i_vio') = cvxts(:,:,'iv') - cvxts(:,:,'b_max');
                cvxts(:,:,'f_vio') = cvxts(:,:,'fv') - cvxts(:,:,'b_max');
                tmp = cvxts(:,:,{'i_vio','f_vio'});
                tmp(tmp <= 0) = NaN;
                cvxts(:,:,{'i_vio','f_vio'}) = tmp; 
                cvxts.unit = Unit.(unit);
                cvxts.desc = strrep(class(cons), 'com.axiomainc.portfolioprecision.optimization.constraints.', '');
                
                vios.(cname) = chfield(cvxts, flds, tblflds, 2);
            end
        end
     end
end  % of classdef

function varargout = javaset2xts(date, varargin)
    varargout = cell(nargin-1, 1);
    for i = 1:nargin-1
        set = varargin{i};
        it = set.iterator;
        secid = cell(1, set.size);
        value = zeros(1, set.size);
        counter = 0;
        while it.hasNext
            asset = it.next();
            counter = counter + 1;
            secid{counter} = char(asset.getAsset.getIdentity);
            value(counter) = asset.getValue;
        end
        varargout{i} = myfints(date, value, secid);
    end
end

function ts = struct2xts(st, date)
    flds = fieldnames(st);
    N = length(flds);
    vals = cell(1, N);
    for i = 1:N
        vals{i} = st.(flds{i});
        if isstruct(vals{i})
            vals{i} = struct2xts(vals{i}, date);
        end
        if isa(vals{i},'xts')
            vals{i}.desc = flds{i};
        end
    end
    if isa(vals{1},'xts')
        [vals{:}] = alignfields(vals{:}, 'union');
        ts = cat(3, vals{:});
    else
        ts = myfints(date, vals, flds);
    end
end

function addAxiomaJavaPath
    AxiomaRoot = 'D:\Program Files\Axioma\API\lib\';
    x = dir([AxiomaRoot '*.jar']);
    x = arrayfun(@(s) {s.name}, x);

    CurrentPath = javaclasspath('-all');
    PathToAdd = cellfun(@(c) {[AxiomaRoot c]},x);
    ToAdd = ismember(PathToAdd,CurrentPath);
    x = x(~ToAdd);
    for i=1:size(x,1)
        javaaddpath(strcat(AxiomaRoot,x{i}),'-end');
    end
end

% function SetConstraintAttribution(str)
%     doAlphaDecomp = true;
%     doHoldingsDecomp = true;
% 
%     decomp = str.getDecomposition();
%     decomp.setAlphaDecompEnabled(doAlphaDecomp);
%     decomp.setHoldingsDecompEnabled(doHoldingsDecomp);
%     if doHoldingsDecomp
%         decomp.setHoldingsDecompBase(str.getConstraint()) %Set Risk Obj/Constraint of which to base holdings decomposition
%     end
% 
%     %% Add all constraints to decomposition
%     clist = str.getConstraints();
%     cit = clist.iterator();
%     while(cit.hasNext())
%         cons = cit.next(); %Constraint object in strategy
%         consdecomp = com.axiomainc.portfolioprecision.optimization.DecompositionGroup(decomp,cons.getIdentity(),'');
%         consdecomp.addConstraint(cons);
%     end
% 
%     %% Add all objective terms to decomposition
%     objlist = str.getObjectiveTerms();
%     oit = objlist.iterator();
%     while(oit.hasNext())
%         obj = oit.next();
%         objdecomp = com.axiomainc.portfolioprecision.optimization.DecompositionGroup(decomp,obj.getIdentity(),'');
%         objdecomp.addObjectiveTerm(obj);
%     end
% 
%     %% Add all implicit constraints to decomposition
%     impcons = com.axiomainc.portfolioprecision.optimization.DecompositionGroup(decomp,'ImplicitConstraints','Group for implicit constraint');
%     impcons.addConstraint(com.axiomainc.portfolioprecision.optimization.Decomposition.IMPLICIT_GRANDFATHER_BOUNDS_CON);
%     impcons.addConstraint(com.axiomainc.portfolioprecision.optimization.Decomposition.IMPLICIT_LOCAL_UNIVERSE_CON);
%     impcons.addConstraint(com.axiomainc.portfolioprecision.optimization.Decomposition.IMPLICIT_NO_CROSSOVER_CON);
%     impcons.addConstraint(com.axiomainc.portfolioprecision.optimization.Decomposition.IMPLICIT_NO_SHORTING_CON);
% end
% 
% function axopt = GetConstraintAttribution(axopt,sol,doAlphaDecomp,doHoldingsDecomp)
%     try
%         sol.doDecomposition(); %% Compute decomposition values
%     catch err
%         disp(err);
%     end
% 
%     ids = cell(axopt.ws.getMasterSet.size(),1);
%     ait = axopt.ws.getMasterSet().iterator();
%     i = 1;
%     while(ait.hasNext())
%         a = ait.next();
%         ids{i} = char(a.getIdentity());
%         i=i+1;
%     end
% 
%     if doAlphaDecomp
%         %                 alphaDecomp = sol.getAlphaDecomposition();
%         %                 [aids, alphaColNames, alphaDecompMatrix] = getDecompositionAsMatrix(ids,alphaDecomp,sol.getAlphaResidual());
%     end
% 
%     if doHoldingsDecomp
%         %                 holdingsDecomp = sol.getHoldingsDecomposition();
%         %                 [hids, holdingsColNames, holdingdsDecompMatrix] = getDecompositionAsMatrix(ids,holdingdsDecomp,sol.getHoldingsResidual());
%     end
% end
% 
% function [ids, colNames, decompMatrix] = getDecompositionAsMatrix(ids,decomp,residual)
%     colNames = cell(decomp.size(),1);
%     decompMatrix = zeros(length(ids),decomp.size());
% 
%     it = decomp.entrySet().iterator();
%     colcount = 1;
%     while(it.hasNext())
%         entry = it.next();
%         decompGroup = entry.getKey();
%         assetValues = entry.getValue();
% 
%         colNames{colcount} = char(decompGroup.getIdentity());
%         avit = assetValues.iterator();
%         while(avit.hasNext())
%             av = avit.next(); % asset values
%             decompMatrix(strcmp(char(av.getAsset().getIdentity()),ids),colcount) = av.getValue();
%         end
%         colcount = colcount + 1;
%     end
%     rit = residual.iterator();
%     residualVector = zeros(length(ids),1);
%     while(rit.hasNext())
%         av = rit.next();
%         residualVector(strcmp(char(av.getAsset().getIdentity()),ids)) = av.getValue();
%     end
%     colNames{decomp.size()} = 'Residuals';
%     decompMatrix = [decompMatrix residualVector];
% end
% 
