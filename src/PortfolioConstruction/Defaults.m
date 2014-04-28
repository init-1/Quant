classdef Defaults
    methods (Static)
        function ds = dataset(dsparam)
            %% Create Data Set
            TRACE('Creating AXDataSet ... ');
            ds = AXDataSet(dsparam.islive,dsparam.dates,dsparam.aggid);
            TRACE('done\n');
            %% Price Group
            TRACE('Loading Price ... ');
            ds('PRICE') = AXDBTemplate.LoadDataItem(ds,{'sects'},{'1051'},10,Unit.PRICE);
            TRACE('done\n');
            %% Shares Group
            TRACE('Loading Shares ... ');
            ds('SHARES') = AXDBTemplate.LoadDataItem(ds,{'sects'},{'159'},10,Unit.SHARES);
            TRACE('done\n');
            %% Volume Group
            TRACE('Loading Volumes ... ');
            ds('VOL1M') = AXDBTemplate.LoadDataItem(ds,{'sects'},{'158'},10,Unit.SHARES,@(x) ftsmovfun(x,22,@nanmean));
            ds('VOL1MNEG') = AXDBTemplate.LoadDataItem(ds,{'sects'},{'158'},10,Unit.SHARES,@(x) -ftsmovfun(x,22,@nanmean));
            TRACE('done\n');
            %% Factor Data
            try
                TRACE('Loading Factor Attributes ... ');
                fts = AXDBTemplate.LoadDataItem(ds,{'factor'},{'F00001'},10,Unit.TEXT);
                fts = normalize(fts,'method',['rankbucket' num2str(dsparam.numbuckets)],'mode','descend');
                ds.add('VALUE',fts,'METAGROUP');
                fts = AXDBTemplate.LoadDataItem(ds,{'factor'},{'F00073'},10,Unit.TEXT);
                fts = normalize(fts,'method',['rankbucket' num2str(dsparam.numbuckets)],'mode','descend');
                ds.add('MOMENTUM',fts,'METAGROUP');
                fts = AXDBTemplate.LoadDataItem(ds,{'factor'},{'F00072'},10,Unit.TEXT);
                fts = normalize(fts,'method',['rankbucket' num2str(dsparam.numbuckets)],'mode','descend');
                ds.add('SIZE',fts,'METAGROUP');
                fts = AXDBTemplate.LoadDataItem(ds,{'factor'},{'F00005'},10,Unit.NUMBER);
                ds.add('DY0',fts,'GROUP');
                fts = AXDBTemplate.LoadDataItem(ds,{'factor'},{'F00149'},10,Unit.NUMBER);
                ds.add('DY1',fts,'GROUP');
                TRACE('done\n');
            catch e
                if ~strcmpi(e.identifier,'LOADDATA:NODATA')
                    rethrow(e);
                end
                TRACE('Factor Attributes failed.\n');
            end     
            %% Model Classification
            if ~isempty(dsparam.modelclass)
                assert(isa(dsparam.modelclass,'xts'),'Input must be a xts object.');
                assert(length(ds.dates)==length(intersect(ds.dates,dsparam.modelclass.dates)),'Missing coverage from model classification.');
                TRACE('Creating Model Classification ... ');
                ds.add('MODEL',dsparam.modelclass,'METAGROUP');
                TRACE('done\n');
            end
            %% Market Cap Buckets
            TRACE('Loading Market Cap Attributes ... ');
            fts = AXDBTemplate.LoadDataItem(ds,{'sects','sects'},{1051,159},[10,10],Unit.TEXT,@(x,y) x.*y);
            fts = normalize(fts,'method',['cumbucket' num2str(dsparam.numbuckets)],'mode','descend');
            ds.add('MC',fts,'METAGROUP');
            TRACE('done\n');
            %% GICS Sector Classifications
            TRACE('Loading GICS Classifications ... ');
            AXDBTemplate.LoadAttribute(ds,'S',Unit.NUMBER,'METAGROUP','axapi.GetGICS',10,1);
            AXDBTemplate.LoadAttribute(ds,'IG',Unit.NUMBER,'METAGROUP','axapi.GetGICS',10,2);
            TRACE('done\n');
            %% Country Classifications
            TRACE('Loading Country Classifications ... ');
            AXDBTemplate.LoadAttribute(ds,'C',Unit.NUMBER,'METAGROUP','axapi.GetSecMstr','isnull(MSCICtry,Country)');
            TRACE('done\n');
            %% Currency Classifications
            TRACE('Loading Currency Classifications ... ');
            AXDBTemplate.LoadAttribute(ds,'CURR',Unit.NUMBER,'METAGROUP','axapi.GetSecMstr','IsoCurId');
            TRACE('done\n');
            %% TCost Model
            TRACE('Loading Transaction Cost Estimates ... ');
            switch lower(dsparam.tcmodel)
                case {'qsg'}
                    TCQSG('TCM',ds,0,'USD');
                case {'simple'}
                    TCSimple('TCM',ds,0,'USD');
                case {'flat'}
                    TCFlat('TCM',ds,0,'USD');
            end
            TRACE('done\n');
            %% Realized Cost
            TRACE('Loading Realized Transaction Costs ... ');
            TCRealized('TCR',ds);
            TRACE('done\n');
            %% Risk Model
            TRACE('Loading Risk Models ... ');
            switch lower(dsparam.riskmodel)
                case {'barra'}
                    RiskBarra('RISKMODEL',ds);
                case {'ema'}
                    RiskEMA('RISKMODEL',ds);
                case {'emcustom'}
                    RiskEMCustom('RISKMODEL',ds);
                case {'ubs'}
                    RiskUBS('RISKMODEL',ds);
            end
            RiskDummy('RISKDUMMY',ds);
            TRACE('done\n');
            %% Sector Beta
            TRACE('Loading Sector Beta ... ');
            Beta = ds('RISKMODEL');
            Beta = Beta.beta;
            GICS = LoadQSSecTS(fieldnames(Beta,1),913,0,datestr(Beta.dates(1),'yyyy-mm-dd'),datestr(Beta.dates(end),'yyyy-mm-dd'));
            [Beta, GICS] = aligndata(Beta,GICS,Beta.dates);
            GICS = uniftsfun(GICS,@(x) floor(x/1000000));
            for i=10:5:55
               Beta_Temp = Beta;
               Beta_Temp(GICS~=i) = 0;
               ds.add(['BETA' num2str(i)],Beta_Temp,'GROUP');
            end
            TRACE('done\n');
            %% Alpha
            ds = Defaults.replacealpha(ds,dsparam.signal);
            %% No Alpha Asset Set
            TRACE('Creating Asset Sets ... ');
            fts = myfints(ds.dates,repmat([1, 0],length(ds.dates),1),{['X' strrep(dsparam.aggid,' ','_')], 'ALPHA'});
            ds.add('NOALPHA',fts,'SET');
            TRACE('done\n');
            %% Inital Portfolio
            TRACE('Loading Accounts ... ');
            if isa(dsparam.startport,'myfints')
                assert(ismember(min(ds.dates),dsparam.startport.dates),'Invalid Starting Portfolio.');        
                dsparam.startport.unit = Unit.SHARES;
                ds.add('ACCOUNT',dsparam.startport,'ACCOUNT');
            elseif isnumeric(dsparam.startport)
                fts = myfints(ds.dates,repmat(dsparam.startport,size(ds.dates)),'CASH');
                ds.add('ACCOUNT',fts,'ACCOUNT');
            end
            TRACE('done\n');
        end
       
        function rebal = rebalancing(setting)
            rebal = AXRebalancing('Rebalancing' ...
                , 'benchmarkId', upper(setting.benchmark) ...
                , 'roundlotsId', upper(setting.roundlotgroup) ...
                , 'accountId', upper(setting.account) ...
                , 'alphaId', upper(setting.alpha) ...
                , 'betaId', upper(setting.beta) ...
                , 'priceId', upper(setting.price) ...
                , 'riskmodelId', upper(setting.riskmodel) ...
                , 'tcmodelId', upper(setting.tcmodel) ...
                , 'rcmodelId', upper(setting.rcmodel) ...
                , 'cashflow', setting.cashflow ...
                , 'minruntime', setting.runtimemin ...
                , 'maxruntime', setting.runtimemax ...
                , 'budgetsize', setting.budgetsize ...
                , 'volumeId', setting.volume);
        end
        
        function cons = constraints(parameter)
           %% Create Period Independent constraints
            cnsts = {};
            fn = fieldnames(parameter);
            isactive = parameter.isactive;
            % Existence of Budget Constraint is assumed to imply Long Only.
            i=0;
            % Active Stock Bet
            c = AXConstraint('ActiveStockBet','LimitHoldingConstraint');
            c.MAX = parameter.actbet.value*100;
            c.MIN = -1*parameter.actbet.value*100;
            c.BENCHMARK = 'REBALANCING.BENCHMARK';
            c.SCOPE = 'ASSET';
            c.UNIT = Unit.PERCENT;
            if isactive == 1
                c.selection = 'LOCAL_UNIVERSE';
            else
                c.selection = 'NON-CASH ASSETS';
            end
            if parameter.actbet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.actbet.maxviolation*100;
            end
            if parameter.actbet.priority > 0
                c.priority = parameter.actbet.priority;
            end
            if ~isinf(parameter.actbet.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Active Stock Bet (No Alpha)
            c = AXConstraint('ActiveNoAlphaBet','LimitHoldingConstraint');
            c.MAX = parameter.noalphabet.value*100;
            c.MIN = -1*parameter.noalphabet.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'ASSET';
            c.UNIT = Unit.PERCENT;
            c.selection = 'NOALPHA';
            if parameter.noalphabet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.noalphabet.maxviolation*100;
            end
            if parameter.noalphabet.priority > 0
                c.priority = parameter.noalphabet.priority;
            end
            if ~isinf(parameter.noalphabet.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Active Holding Liquidity
            c = AXConstraint('ActiveHoldingLiquidity','LimitHoldingConstraint');
            c.MAX_VALUES_GROUP = 'VOL1M';
            c.MIN_VALUES_GROUP = 'VOL1MNEG';
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.WEIGHT = 1.0/parameter.holdtoadv.value;
            c.WEIGHTED = true;
            c.UNIT = Unit.SHARES;
            c.SCOPE = 'ASSET';
            c.selection = 'LOCAL_UNIVERSE';
            if parameter.holdtoadv.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.holdtoadv.maxviolation;
            end
            if parameter.holdtoadv.priority > 0
                c.priority = parameter.holdtoadv.priority;
            end
            if ~isinf(parameter.holdtoadv.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Active Sector Bet
            c = AXConstraint('ActiveSectorBet','LimitHoldingConstraint');
            c.MAX = parameter.sectorbet.value*100;
            c.MIN = -1*parameter.sectorbet.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'S';
            if parameter.sectorbet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.sectorbet.maxviolation*100;
            end
            if parameter.sectorbet.priority > 0
                c.priority = parameter.sectorbet.priority;
            end
            if ~isinf(parameter.sectorbet.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Active Industry Group Bet
            c = AXConstraint('ActiveIndGrpBet','LimitHoldingConstraint');
            c.MAX = parameter.indgrpbet.value*100;
            c.MIN = -1*parameter.indgrpbet.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'IG';
            if parameter.indgrpbet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.indgrpbet.maxviolation*100;
            end
            if parameter.indgrpbet.priority > 0
                c.priority = parameter.indgrpbet.priority;
            end
            if ~isinf(parameter.indgrpbet.value)
                i=i+1;
                cnsts{i,1} = c;
            end
            
            % Active Country Bet
            c = AXConstraint('ActiveCountryBet','LimitHoldingConstraint');
            c.MAX = parameter.ctrybet.value*100;
            c.MIN = -1*parameter.ctrybet.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'C';
            if parameter.ctrybet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.ctrybet.maxviolation*100;
            end
            if parameter.ctrybet.priority > 0
                c.priority = parameter.ctrybet.priority;
            end
            if ~isinf(parameter.ctrybet.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Active Currency Bet
            c = AXConstraint('ActiveCurrencyBet','LimitHoldingConstraint');
            c.MAX = parameter.currbet.value*100;
            c.MIN = -1*parameter.currbet.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'CURR';
            if parameter.currbet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.currbet.maxviolation*100;
            end
            if parameter.currbet.priority > 0
                c.priority = parameter.currbet.priority;
            end
            if ~isinf(parameter.currbet.value)
                i=i+1;
                cnsts{i,1} = c;
            end
            
            % Active Beta
            c = AXConstraint('ActiveBeta', 'LimitWeightedAvgConstraint');
            c.SCOPE = 'AGGREGATE';
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
                c.BASE_SET = 'LOCAL_UNIVERSE';
                c.UNIT = Unit.PERCENT;
                scale = 100;
            else
                c.BASE_SET = 'NON-CASH ASSETS';
                c.UNIT = Unit.NUMBER;
                scale = 1;
            end
            c.MAX = parameter.actbeta.value*scale;
            c.MIN = -1*parameter.actbeta.value*scale;
            c.selection = 'RISKMODEL.BETA';
            if parameter.actbeta.priority > 0
                c.priority = parameter.actbeta.priority;
            end
            % No Penalty for LimitWeightedAvgConstraint
            if ~isinf(parameter.actbeta.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Active Sector Beta
            c = AXConstraint('ActiveSectorBeta', 'LimitWeightedAvgConstraint');
            c.SCOPE = 'SELECTION';
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
                c.BASE_SET = 'LOCAL_UNIVERSE';
                c.UNIT = Unit.PERCENT;
                scale = 100;
            else
                c.BASE_SET = 'NON-CASH ASSETS';
                c.UNIT = Unit.NUMBER;
                scale = 1;
            end
            c.MAX = parameter.sectorbeta.value*scale;
            c.MIN = -1*parameter.sectorbeta.value*scale;
            c.selection = {'BETA10','BETA15','BETA20','BETA25','BETA30','BETA35','BETA40','BETA45','BETA50','BETA55'};
            if parameter.sectorbeta.priority > 0
                c.priority = parameter.sectorbeta.priority;
            end
            % No Penalty for LimitWeightedAvgConstraint
            if ~isinf(parameter.sectorbeta.value)
                i=i+1;
                cnsts{i,1} = c;
            end
            
            % Tracking Error
            c = AXConstraint('TrackingError', 'LimitTotalRiskConstraint');
            c.SCOPE = 'AGGREGATE';
            c.UNIT = Unit.PERCENT;
            c.MAX = parameter.maxte.value*100;
            c.FACTOR_WEIGHT = 1;
            c.SPECIFIC_WEIGHT = 1;
            c.BENCHMARK = 'REBALANCING.BENCHMARK';
            c.RISKMODEL = 'RISKMODEL';
            c.selection = 'LOCAL_UNIVERSE';
            if parameter.maxte.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.maxte.maxviolation*100;
            end
            if parameter.maxte.priority > 0
                c.priority = parameter.maxte.priority;
            end
            if ~isinf(parameter.maxte.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Threshold Holding
            c = AXConstraint('ThresholdHolding','ThresholdHoldingConstraint');
            c.SCOPE = 'ASSET';
            c.UNIT = Unit.PERCENT;
            c.MIN = parameter.minholding.value*100;
            c.selection = 'LOCAL_UNIVERSE';            
            if parameter.minholding.priority > 0
                c.priority = parameter.minholding.priority;
            end
            % No Penalty for ThresholdHolding
            if parameter.minholding.value > 0 
                i=i+1;
                cnsts{i,1} = c;
            end
            
            % Threshold Trade
            c = AXConstraint('ThresholdTrade','ThresholdTradeConstraint');
            c.SCOPE = 'ASSET';
            c.UNIT = Unit.PERCENT;
            c.MIN = parameter.mintrade.value*100;
            c.selection = 'NON-CASH ASSETS';            
            if parameter.mintrade.priority > 0
                c.priority = parameter.mintrade.priority;
            end
            % No Penalty for ThresholdTrade
            if parameter.mintrade.value > 0 
                i=i+1;
                cnsts{i,1} = c;
            end

            % Names
            c = AXConstraint('Names', 'LimitNamesConstraint');
            c.SCOPE = 'AGGREGATE';
            if ~isinf(parameter.name.value(1))
                c.MIN = parameter.name.value(1);
            end
            if ~isinf(parameter.name.value(2))
                c.MAX = parameter.name.value(2);
            end
            c.selection = 'MASTER';
            if parameter.name.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.name.maxviolation;
            end
            if parameter.name.priority > 0
                c.priority = parameter.name.priority;
            end
            if parameter.name.value(1) > 0 || parameter.name.value(2) < Inf
                i=i+1;
                cnsts{i,1} = c;
            end

            % MCap Bucket
            c = AXConstraint('ActiveMCapBet','LimitHoldingConstraint');
            c.MAX = parameter.mcap.value*100;
            c.MIN = -1*parameter.mcap.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'MC';
            if parameter.mcap.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.mcap.maxviolation*100;
            end
            if parameter.mcap.priority > 0
                c.priority = parameter.mcap.priority;
            end
            if ~isinf(parameter.mcap.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Value Bucket
            c = AXConstraint('ActiveValueBet','LimitHoldingConstraint');
            c.MAX = parameter.value.value*100;
            c.MIN = -1*parameter.value.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'VALUE';
            if parameter.value.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.value.maxviolation*100;
            end
            if parameter.value.priority > 0
                c.priority = parameter.value.priority;
            end
            if ~isinf(parameter.value.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Momentum Bucket
            c = AXConstraint('ActiveMomentumBet','LimitHoldingConstraint');
            c.MAX = parameter.momentum.value*100;
            c.MIN = -1*parameter.momentum.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'MOMENTUM';
            if parameter.momentum.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.momentum.maxviolation*100;
            end
            if parameter.momentum.priority > 0
                c.priority = parameter.momentum.priority;
            end
            if ~isinf(parameter.momentum.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Size Bucket
            c = AXConstraint('ActiveSizeBet','LimitHoldingConstraint');
            c.MAX = parameter.size.value*100;
            c.MIN = -1*parameter.size.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.selection = 'SIZE';
            if parameter.size.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.size.maxviolation*100;
            end
            if parameter.size.priority > 0
                c.priority = parameter.size.priority;
            end
            if ~isinf(parameter.size.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Active Dividend Yield FY0
            c = AXConstraint('ActiveDY0', 'LimitWeightedAvgConstraint');
            c.SCOPE = 'AGGREGATE';
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
                c.BASE_SET = 'LOCAL_UNIVERSE';
                c.UNIT = Unit.PERCENT;
                scale = 100;
            else
                c.BASE_SET = 'NON-CASH ASSETS';
                c.UNIT = Unit.NUMBER;
                scale = 1;
            end
            c.MAX = parameter.dy0.value*scale;
            c.MIN = -1*parameter.dy0.value*scale;
            c.selection = 'DY0';
            if parameter.dy0.priority > 0
                c.priority = parameter.dy0.priority;
            end
            % No Penalty for LimitWeightedAvgConstraint
            if ~isinf(parameter.dy0.value)
                i=i+1;
                cnsts{i,1} = c;
            end            
            
            % Active Dividend Yield FY1
            c = AXConstraint('ActiveDY1', 'LimitWeightedAvgConstraint');
            c.SCOPE = 'AGGREGATE';
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
                c.BASE_SET = 'LOCAL_UNIVERSE';
                c.UNIT = Unit.PERCENT;
                scale = 100;
            else
                c.BASE_SET = 'NON-CASH ASSETS';
                c.UNIT = Unit.NUMBER;
                scale = 1;
            end
            c.MAX = parameter.dy1.value*scale;
            c.MIN = -1*parameter.dy1.value*scale;
            c.selection = 'DY1';
            if parameter.dy1.priority > 0
                c.priority = parameter.dy1.priority;
            end
            % No Penalty for LimitWeightedAvgConstraint
            if ~isinf(parameter.dy1.value)
                i=i+1;
                cnsts{i,1} = c;
            end
            
            % Absolute Stock Bet
            c = AXConstraint('AbsoluteStockBet','LimitAbsoluteHoldingConstraint');
            c.MAX = parameter.pfbet.value*100;
            c.SCOPE = 'ASSET';
            c.UNIT = Unit.PERCENT;
            c.selection = 'NON-CASH ASSETS';
            if parameter.pfbet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.pfbet.maxviolation*100;
            end
            if parameter.pfbet.priority > 0
                c.priority = parameter.pfbet.priority;
            end
            if ~isinf(parameter.pfbet.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Max Shares Outstanding
            c = AXConstraint('AbsoluteShares','LimitAbsoluteHoldingConstraint');
            c.MAX_VALUES_GROUP = 'SHARES';
            c.WEIGHT = 1.0/parameter.maxmcap.value;
            c.WEIGHTED = true;
            c.SCOPE = 'ASSET';
            c.UNIT = Unit.PERCENT;
            c.selection = 'LOCAL_UNIVERSE';
            if parameter.maxmcap.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.maxmcap.maxviolation;
            end
            if parameter.maxmcap.priority > 0
                c.priority = parameter.maxmcap.priority;
            end
            if ~isinf(parameter.maxmcap.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Risk Factor Neutral
            c = AXConstraint('RiskModelFactor','LimitHoldingConstraint');
            c.selection = 'RISKMODEL.COMMON FACTORS';
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.MAX = parameter.riskfactorbet.value*100;
            c.MIN = -1*parameter.riskfactorbet.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            if parameter.riskfactorbet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.riskfactorbet.maxviolation*100;
            end
            if parameter.riskfactorbet.priority > 0
                c.priority = parameter.riskfactorbet.priority;
            end
            if ~isinf(parameter.riskfactorbet.value)
                i=i+1;
                cnsts{i,1} = c;
            end

            % Model Neutral
            c = AXConstraint('ModelNeutrality','LimitHoldingConstraint');
            c.selection = 'MODEL';
            c.SCOPE = 'MEMBER';
            c.UNIT = Unit.PERCENT;
            c.MAX = parameter.modelbet.value*100;
            c.MIN = -1*parameter.modelbet.value*100;
            if isactive == 1
                c.BENCHMARK = 'REBALANCING.BENCHMARK';
            end
            if parameter.modelbet.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.modelbet.maxviolation*100;
            end
            if parameter.modelbet.priority > 0
                c.priority = parameter.modelbet.priority;
            end
            if ~isinf(parameter.modelbet.value)
                i=i+1;
                cnsts{i,1} = c;
            end
            
            %% Long Only Constraints
            % Budget
            if ismember('budget',fn)
                c = AXConstraint('Budget', 'BudgetConstraint');
                c.UNIT = Unit.CURRENCY;
                c.USE_BUDGET_VALUE = parameter.budget.value;                         
                if parameter.budget.priority > 0
                    c.priority = parameter.budget.priority;
                end
                i=i+1;
                cnsts{i,1} = c;   
            end
            
            %% Long/Short Constraints
            % Long Holding
            if ismember('longhldg',fn)
                c = AXConstraint('LongHoldong','LimitLongHoldingConstraint');
                c.selection = 'NON-CASH ASSETS';
                c.SCOPE = 'AGGREGATE';
                c.UNIT = Unit.PERCENT;
                c.MAX = parameter.longhldg.value*100;
                c.MIN = parameter.longhldg.value*100;
                if parameter.longhldg.maxviolation > 0
                    c.PENALTY_TYPE = 'LINEAR';
                    c.PENALTY = 5;
                    c.MAX_VIOLATION = parameter.longhldg.maxviolation*100;
                end
                if parameter.longhldg.priority > 0
                    c.priority = parameter.longhldg.priority;
                end
                if ~isinf(parameter.longhldg.value)
                    i=i+1;
                    cnsts{i,1} = c;
                end
            end
            
            % Short Holding
            if ismember('shorthldg',fn)
                c = AXConstraint('ShortHoldong','LimitShortHoldingConstraint');
                c.selection = 'NON-CASH ASSETS';
                c.SCOPE = 'AGGREGATE';
                c.UNIT = Unit.PERCENT;
                c.MAX = parameter.shorthldg.value*100;
                c.MIN = parameter.shorthldg.value*100;
                if parameter.shorthldg.maxviolation > 0
                    c.PENALTY_TYPE = 'LINEAR';
                    c.PENALTY = 5;
                    c.MAX_VIOLATION = parameter.shorthldg.maxviolation*100;
                end
                if parameter.shorthldg.priority > 0
                    c.priority = parameter.shorthldg.priority;
                end
                if ~isinf(parameter.shorthldg.value)
                    i=i+1;
                    cnsts{i,1} = c;
                end
            end
            
            % Cash Holding
            if ismember('cashhldg',fn)
                c = AXConstraint('CashHoldong','LimitHoldingConstraint');
                c.selection = 'CASH';
                c.SCOPE = 'ASSET';
                c.UNIT = Unit.PERCENT;
                c.MAX = parameter.cashhldg.value*100;
                c.MIN = parameter.cashhldg.value*100;
                if parameter.cashhldg.maxviolation > 0
                    c.PENALTY_TYPE = 'LINEAR';
                    c.PENALTY = 5;
                    c.MAX_VIOLATION = parameter.cashhldg.maxviolation*100;
                end
                if parameter.cashhldg.priority > 0
                    c.priority = parameter.cashhldg.priority;
                end
                if ~isinf(parameter.cashhldg.value)
                    i=i+1;
                    cnsts{i,1} = c;
                end
            end
            
            % Long Bets
            if ismember('longbet',fn)
                c = AXConstraint('LongBets','LimitHoldingConstraint');
                c.selection = 'ALPHABUCKET.1';
                c.SCOPE = 'ASSET';
                c.UNIT = Unit.PERCENT;
                c.MIN = parameter.longbet.value*100;
                if parameter.longbet.maxviolation > 0
                    c.PENALTY_TYPE = 'LINEAR';
                    c.PENALTY = 5;
                    c.MAX_VIOLATION = parameter.longbet.maxviolation*100;
                end
                if parameter.longbet.priority > 0
                    c.priority = parameter.longbet.priority;
                end
                if ~isinf(parameter.longbet.value)
                    i=i+1;
                    cnsts{i,1} = c;
                end
            end
            
            % Short Bets
            if ismember('shortbet',fn)
                c = AXConstraint('ShortBets','LimitHoldingConstraint');
                c.selection = 'ALPHABUCKET.2';
                c.SCOPE = 'ASSET';
                c.UNIT = Unit.PERCENT;
                c.MAX = parameter.shortbet.value*100;
                if parameter.shortbet.maxviolation > 0
                    c.PENALTY_TYPE = 'LINEAR';
                    c.PENALTY = 5;
                    c.MAX_VIOLATION = parameter.shortbet.maxviolation*100;
                end
                if parameter.shortbet.priority > 0
                    c.priority = parameter.shortbet.priority;
                end
                if ~isinf(parameter.shortbet.value)
                    i=i+1;
                    cnsts{i,1} = c;
                end
            end
            
            %% Period Specific Constraints
            cnsts_begin = cnsts;

            % Turnover
            c = AXConstraint('Turnover','LimitTurnoverConstraint');
            c.MAX = parameter.maxto.value*100;
            c.UNIT = Unit.PERCENT;
            c.SCOPE = 'AGGREGATE';
            c.selection = 'NON-CASH ASSETS';
            if parameter.maxto.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.maxto.maxviolation*100;
            end
            if parameter.maxto.priority > 0
                c.priority = parameter.maxto.priority;
            end
            if ~isinf(parameter.maxto.value)
                i=i+1;
                cnsts{i,1} = c;
                if ~ismember('budget',fn)
                    c.MAX = 200;
                else
                    c.MAX = 100;    
                end
                cnsts_begin{i,1} = c;
            end

            % Trade Liquidity
            c = AXConstraint('TradeLiquidity','LimitTurnoverConstraint');
            c.MAX_VALUES_GROUP = 'VOL1M';
            c.WEIGHT = 1.0/parameter.tradetoadv.value;
            c.WEIGHTED = true;
            c.UNIT = Unit.SHARES;
            c.SCOPE = 'ASSET';
            c.selection = 'LOCAL_UNIVERSE';
            if parameter.tradetoadv.maxviolation > 0
                c.PENALTY_TYPE = 'LINEAR';
                c.PENALTY = 5;
                c.MAX_VIOLATION = parameter.tradetoadv.maxviolation*100;
            end
            if parameter.tradetoadv.priority > 0
                c.priority = parameter.tradetoadv.priority;
            end
            if ~isinf(parameter.tradetoadv.value)
                i=i+1;
                cnsts{i,1} = c;
                c.isEnabled = false;    
                cnsts_begin{i,1} = c;
            end
            
            cons.initial = cnsts_begin;
            cons.period = cnsts;
        end
        
        function obj = objective(parameter)
            switch lower(parameter.objective.name)
                case {'mvo'}
                    obj = AXObjective(parameter.objective.name,'MAXIMIZE');
                    obj = obj.addExpectedReturnObjective('ExpRet','REBALANCING.ALPHA_GROUP',1);
                    obj = obj.addRiskObjective('ActiveRisk','REBALANCING.BENCHMARK','REBALANCING.RISK_MODEL',-1*parameter.objective.weight);
                case {'maxret'}
                    obj = AXObjective(parameter.objective.name,'MAXIMIZE');
                    obj = obj.addExpectedReturnObjective('ExpRet','REBALANCING.ALPHA_GROUP',1);
                    obj = obj.addTransactionCostObjective('TC',-1*parameter.objective.weight);
%                 case {'maximpret'}
%                     obj = AXObjective(parameter.objective.name,'MAXIMIZE');
%                     obj = obj.addExpectedReturnObjective('ExpRet','IMPALPHA',1);
%                     obj = obj.addTransactionCostObjective('TC',-1*parameter.objective.weight);
                case {'minte'}
                    obj = AXObjective(parameter.objective.name,'MINIMIZE');
                    obj = obj.addRiskObjective('ActiveRisk','REBALANCING.BENCHMARK','REBALANCING.RISK_MODEL',parameter.objective.weight);
                case {'minsignalte'}
                    obj = AXObjective(parameter.objective.name,'MINIMIZE');
                    obj = obj.addRiskObjective('ActiveRisk','SIGNAL','REBALANCING.RISK_MODEL',parameter.objective.weight);
                case {'minbmsignalte'}
                    obj = AXObjective(parameter.objective.name,'MINIMIZE');
                    obj = obj.addRiskObjective('ActiveRisk','SIGNALBM','REBALANCING.RISK_MODEL',parameter.objective.weight);
                case {'minmsd'}
                    obj = AXObjective(parameter.objective.name,'MINIMIZE');
                    obj = obj.addVarianceObjective('MSD','REBALANCING.BENCHMARK','RISKDUMMY',parameter.objective.weight);
                case {'minsignalmsd'}
                    obj = AXObjective(parameter.objective.name,'MINIMIZE');
                    obj = obj.addVarianceObjective('MSD','SIGNAL','RISKDUMMY',parameter.objective.weight);
                case {'minbmsignalmsd'}
                    obj = AXObjective(parameter.objective.name,'MINIMIZE');
                    obj = obj.addVarianceObjective('MSD','SIGNALBM','RISKDUMMY',parameter.objective.weight);
                otherwise
                    error('Invalid Objective. Objective cannot be created.');
            end 
        end
        
        function stng = setting(dsparam)
            name = {'isshort','runtimemin','runtimemax','cashflow','budgetsize','localinc','localexc' ...
                'price','account','riskmodel','tcmodel','rcmodel','benchmark','alpha','beta','volume','roundlotgroup'};
            value = {0, 5, 60, 0, NaN, 'REBALANCING.BENCHMARK', NaN, 'price', 'account', 'riskmodel', ...
                'tcm', 'tcr', ['X' strrep(dsparam.aggid,' ','_')], 'alpha', 'riskmodel.beta','vol1m', 'roundlotsize'};
            
            for i=1:numel(name)
                stng.(name{i}) = value{i};
            end
        end
        
        function param = parameter(isshort,isactive)
            if ~exist('isshort','var')
                isshort = 0;
            end
            
            name = {'actbet','noalphabet','tradetoadv','holdtoadv','sectorbet','indgrpbet','ctrybet','currbet', ...
                'maxto','actbeta','sectorbeta','maxte','minholding','mintrade','name', ...
                'mcap','value','momentum','size','dy0','dy1','pfbet','maxmcap','riskfactorbet','modelbet'};
            value = {Inf,0,Inf,Inf,0.0025,Inf,0.0025,Inf,0.2,0.05,Inf,0.03,0.0005,0.0005,[0,Inf],...
                Inf,Inf,Inf,Inf,Inf,Inf,0.05,0.05,Inf,Inf};
            
            switch isshort %Long Only/Long Short specific constraints
                case 0
                    name = [name , {'budget'}];
                    value = [value, {1}];
                case 1
                    name = [name, {'longhldg','shorthldg','cashhldg','longbet','shortbet','maxrisk'}];
                    value = [value, {1,1,1,0,0,Inf}];
                otherwise
                    error(['Invalid parameter: IsShort.']);
            end
            
            maxviolation = zeros(1,length(name));
            priority = zeros(1,length(name));
            maxviolation(ismember(name,{'longhldg','shorthldg'})) = 0.0005;
            
            %Create param output
            objective.name = 'maxret';
            objective.weight = 1;
            budgetsize = 100000000;
            
            param.objective = objective;
            param.budgetsize = budgetsize;
            for i=1:numel(name)
                switch lower(name{i})
                    case {'minholding','mintrade','actbeta','sectorbeta','budget'}
                        param.(name{i}).value = value{i};
                        param.(name{i}).priority = priority(i);
                    otherwise
                        param.(name{i}).value = value{i};
                        param.(name{i}).maxviolation = maxviolation(i);
                        param.(name{i}).priority = priority(i);
                end
            end
            param.isactive = isactive;
        end
        
        function prmlist = spanparam(parameter,varargin)
            % Input params
            inputparam = varargin(1:2:end-1);
            inputvalue = varargin(2:2:end);
            
            fn = fieldnames(parameter);
            if ~isempty(inputparam(~ismember(inputparam,fn)))
                illegal = inputparam(ismember(inputparam,fn));
                warning(['The following parameter(s) are illegal and will not be used:',sprintf(' %s',illegal{:}) '.']);
            end
            
            i=1;
            prmlist{i} = parameter;
            
            i=i+1;
            for j=1:length(inputparam)
                val = inputvalue{j};
                switch lower(inputparam{j})
                    case {'objective'}
                        for k=1:length(val)
                            prmlist{i} = parameter;
                            prmlist{i}.(inputparam{j}).weight = val(k);
                            i=i+1;
                        end
                    case {'budgetsize'}
                        for k=1:length(val)
                            prmlist{i} = parameter;
                            prmlist{i}.(inputparam{j}) = val(k);
                            i=i+1;
                        end
                    otherwise
                        for k=1:length(val)
                            prmlist{i} = parameter;
                            prmlist{i}.(inputparam{j}).value = val(k);
                            i=i+1;
                        end
                end
            end
        end
        
        function conslist = spancons(ds,parameter,assetcon,attribcon,rebaldates,cons_extra)
            % dates:     is an array of datenums
            % parameter: the output created via Defaults.parameter
            % assetcon:  a structure with fieldnames {'position','trade'},           
            %            each containing cell arrays of (n x n x 4) xts. 
            %            The four fieldnames in the 3rd dimension
            %            should be {'min','max','maxviolation','priority'}.
            %            xts.desc refers to the scope of the fields. (i.e.
            %            asset, selection, member, aggregate.
            if ~exist('rebaldates','var')
                rebaldates = ds.dates;
            end
            dates = ds.dates;
            cons = Defaults.constraints(parameter);
            if numel(dates) == 1
                cons.initial = cons.period;
            end
            % Add Extra Constraints
            if exist('cons_extra','var')
                if ~isempty(cons_extra)
                    cons.initial = [cons.initial ; cons_extra.initial];
                    cons.period = [cons.period ; cons_extra.period];
                end
            end
            conslist = cell(1,length(dates));
            for i=1:length(dates)
                if dates(i) ~= min(rebaldates)
                    conslist{i} = cons.period;  
                else
                    conslist{i} = cons.initial;
                end
            end
            
            if ~isempty(assetcon)
                for i = 1:length(assetcon)
                    if strcmpi(assetcon{i}.type,'position')
                        conslist = spanlimitholding(ds,conslist,assetcon{i});
                    elseif strcmpi(assetcon{i}.type,'trade')
                        conslist = spanlimittrade(ds,conslist,assetcon{i});
                    else
                        warning(['Invalid constraint type ' assetcon{i}.type '. Constraint not loaded.']);
                    end
                end
            end
            
            if ~isempty(attribcon)
                for i = 1:length(attribcon)
                    conslist = spanattrib(ds,conslist,attribcon{i});
                end
            end
            
            function conslist = spanlimitholding(ds,conslist,assetcon)
                dates = ds.dates;
                fts = assetcon.A;
                for k = 1:length(dates)
                    fn = fieldnames(fts,1,1);
                    fn_live = [keys(ds,dates(k)); ds.getUniverse(dates(k))];
                    fn_live = intersect(fn,fn_live);
                    max = fts2mat(fts(datestr(dates(k),'yyyy-mm-dd'),fn_live,'max'));
                    min = fts2mat(fts(datestr(dates(k),'yyyy-mm-dd'),fn_live,'min'));
                    vio = fts2mat(fts(datestr(dates(k),'yyyy-mm-dd'),fn_live,'maxviolation'));
                    idx = ~isnan(max) & ~isnan(min);
                    fn = fn_live(idx);
                    max = max(idx);
                    min = min(idx);
                    vio = vio(idx);
                    vio(isnan(vio)) = 0;
                    
                    % Active Stock Bet
                    c = AXConstraint(['Custom_' assetcon.name],'LimitHoldingConstraint');
                    if ~isnan(max)
                        c.MAX_ARRAY = max*100;
                    end
                    if ~isnan(min)
                        c.MIN_ARRAY = min*100;
                    end
                    if assetcon.isactive == 1
                        c.BENCHMARK = 'REBALANCING.BENCHMARK';
                    end
                    c.SCOPE = upper(fts.desc);
                    c.UNIT = fts.unit;
                    c.selection = upper(fn);
                    if all(vio > 0)
                        c.PENALTY_TYPE = 'LINEAR';
                        c.PENALTY_ARRAY = 5*ones(size(max));
                        c.MAX_VIOLATION_ARRAY = vio*100;
                    end
                    if assetcon.priority > 0
                        c.priority = assetcon.priority;
                    end
                    conslist{k} = [conslist{k} ; {c}];                    
                end 
            end
            
            function conslist = spanlimittrade(ds,conslist,assetcon)
                dates = ds.dates;
                fts = assetcon.A;
                for k = 1:length(dates)
                    fn = fieldnames(fts,1,1);
                    fn_live = [keys(ds,dates(k)); ds.getUniverse(dates(k))];
                    fn_live = intersect(fn,fn_live);
                    max = fts2mat(fts(datestr(dates(k),'yyyy-mm-dd'),fn_live,'max'));
                    min = fts2mat(fts(datestr(dates(k),'yyyy-mm-dd'),fn_live,'min'));
                    vio = fts2mat(fts(datestr(dates(k),'yyyy-mm-dd'),fn_live,'maxviolation'));
                    idx = ~isnan(max) & ~isnan(min);
                    fn = fn_live(idx);
                    max = max(idx);
                    min = min(idx);
                    vio = vio(idx);
                    vio(isnan(vio)) = 0;
                                        
                    % Active Stock Bet
                    c = AXConstraint(['Custom_' assetcon.name],'LimitTradeConstraint');
                    if fts.unit == Unit.PERCENT
                        scale = 100;
                    else
                        scale = 1;
                    end
                    if ~isnan(max)
                        c.MAX_ARRAY = max*scale;
                    end
                    if ~isnan(min)
                        c.MIN_ARRAY = min*scale;
                    end
                    c.SCOPE = upper(fts.desc);
                    c.UNIT = fts.unit;
                    c.selection = upper(fn);
                    if all(vio > 0)
                        c.PENALTY_TYPE = 'LINEAR';
                        c.PENALTY_ARRAY = 5*ones(size(max));
                        c.MAX_VIOLATION_ARRAY = vio*scale;
                    end
                    if assetcon.priority > 0
                        c.priority = assetcon.priority;
                    end
                    conslist{k} = [conslist{k} ; {c}];
                end                 
            end
            
            function conslist = spanattrib(ds,conslist,attribcon)
                dates = ds.dates;
                fts = attribcon.A;
                for k = 1:length(dates)
                    if ~isempty(intersect(dates(k),fts.dates))
                        if fts.unit == Unit.PERCENT || fts.unit == Unit.NUMBER
                            scale = 100;
                        else
                            scale = 1;
                        end
                        c = AXConstraint(['Custom_' attribcon.name],'LimitHoldingConstraint');
                        c.MAX = attribcon.ub*scale;
                        c.MIN = attribcon.lb*scale;
                        c.SCOPE = upper(fts.desc);
                        if fts.unit == Unit.NUMBER
                            c.UNIT = Unit.PERCENT;
                        else
                            c.UNIT = fts.unit;
                        end
                        c.selection = upper(attribcon.name);
                        if attribcon.maxviolation > 0
                            c.PENALTY_TYPE = 'LINEAR';
                            c.PENALTY = 5;
                            c.MAX_VIOLATION = attribcon.maxviolation*scale;
                        end
                        if attribcon.priority > 0
                            c.priority = attribcon.priority;
                        end
                        conslist{k} = [conslist{k} ; {c}];
                    end
                end
            end
        end
        
        function fts = initport(accountid,strategyid,date)
            res = DB('QuantPosition').runSql('dbo.GetStrategyPositions',1,accountid,strategyid,date);
            fts = myfints(datenum(date),res.shares',res.secid');
            fts.unit = Unit.SHARES;
        end
        
        function ds = replacealpha(ds,signal,varargin) %mode,value)
            %% Input params
            option.leverage = 1;
            option.risk = NaN;
            option.model = [];
            option.ntile = 5;
            
            if nargin > 2
                s = warning('query' ,'VAROPTION:UNRECOG');
                warning('off', 'VAROPTION:UNRECOG');
                option = Option.vararginOption(option, {'leverage', 'risk', 'model', 'ntile'}, varargin{:});
                warning(s.state, 'VAROPTION:UNRECOG');
            end
            %% Alpha
            TRACE('Loading Alpha ... ');
            if isa(signal,'myfints')
                long = 1 - 1/option.ntile;
                short = 1/option.ntile;
                bench = ds(['X' strrep(upper(ds.aggid{:}),' ','_')]);
                signal = alignto(bench,signal);  
                signal.unit = Unit.NUMBER;
                ds.add('ALPHA',signal,'GROUP');
                [~,~,~,signalport] = factorPFRtn(signal,signal,signal); %this assumes signal has same coverage as benchmark
                signalport.unit = Unit.PERCENT;
                cash = myfints(signalport.dates,ones(size(signalport.dates))*100,{'CASH'});                
                cash.unit = Unit.PERCENT;
%                 ds.add('IMPALPHA',Defaults.impliedalpha(signalport,ds('RISKMODEL')),'GROUP');                
                if ~isnan(option.risk)
                    mode = 'risk';
                else
                    mode = 'leverage';
                end
                if ~isempty(option.model)
                    assert(isa(option.model,'xts'),'Invalid input for parameter model.');
                    option.model = aligndates(option.model,signal.dates);
                    option.model = padfield(option.model,fieldnames(signal,1),NaN,1);
                    [~, W] = csqtspread(signal,signal,'gics',ftsstr2num(option.model),'univ',bench,'weight',signal,'level','customized','long',long,'short',short);                
                else
                    [~, W] = csqtspread(signal,signal,'univ',bench,'weight',signal);                
                end
                W(W == 0) = NaN;
                W.unit = Unit.PERCENT;
                switch lower(mode)
                    case {'leverage'}
                        sact = signalport.*option.leverage*100;      
                        W = W.*option.leverage*100;
                    case {'risk'}
                        riskmodel = ds('RISKMODEL');
                        signalrisk = myfints(signalport.dates,riskmodel.calcrisk(signalport),{'risk'});
                        signalQrisk = myfints(signalport.dates,riskmodel.calcrisk(W),{'risk'});
                        sact = bsxfun(@rdivide,signalport,signalrisk).*option.risk*100;                 
                        W = bsxfun(@rdivide,W,signalQrisk).*option.risk*100;
                end
                signalportQ = [W cash];                
                signalport = [sact cash];
                ds.add('SIGNAL',signalport,'BENCHMARK');
                ds.add('SIGNALQ',signalportQ,'BENCHMARK');                
                sact = aligndates(sact,bench.dates);
                bench = padfield(bench,fieldnames(sact,1),NaN,1);
                ds.add('SIGNALBM',bench+sact,'BENCHMARK');
                signal = normalize(signal,'method','rankbucket2','mode','descend');
                ds.add('ALPHABUCKET',signal,'METAGROUP');
            elseif ischar(signal)
                signal = ds.loadAlpha(signal);
                ds.add('ALPHA',signal,'GROUP');
                signal = normalize(signal,'method','rankbucket2','mode','descend');
                ds.add('ALPHABUCKET',signal,'METAGROUP');
                AXDBTemplate.LoadBenchmark(ds,'SIGNAL','axapi.GetSignalPortfolio',signal,100);
            end
            TRACE('done\n');            
        end
        
        function alpha = impliedalpha(portfolio,riskmodel)
            [portfolio exposure specrisk] = alignfields(portfolio,riskmodel.exposure,riskmodel.specrisk,1);
            [portfolio exposure specrisk faccov] = aligndates(portfolio,exposure,specrisk,riskmodel.faccov,riskmodel.dates);
            alpha = portfolio;
            for t = 1:length(riskmodel.dates)
                pf = fts2mat(portfolio(t,:))./100;
                pf(isnan(pf)) = 0;
                exp = squeeze(exposure(t,:,:));
                exp(isnan(exp)) = 0;
                spec = fts2mat(specrisk(t,:));
                spec(isnan(spec)) = 0;
                riskmat = exp * squeeze(faccov(t,:,:)) * exp' + spec' * spec;
                riskmat(isnan(riskmat)) = 0;
                a = pf*riskmat;
%                 a = pf*eye(size(riskmat,1));
                a(a==0) = NaN;
                alpha(t,:) = a;
                alpha.unit = Unit.NUMBER;
            end            
        end
        
        function fts = bldmodel(mode,dates,strategyid)
            dates = datenum(dates);
            dates = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},dates);
            datelist = sprintf(',%s',dates{:});
            switch lower(mode)
                case {'alpha'}
                    ret = DB('QuantTrading').runSql('axapi.GetBLDAlpha','',datelist(2:end),strategyid,'');
                case {'model'}
                    ret = DB('QuantTrading').runSql('axapi.GetBLDClassification','',datelist(2:end),strategyid);
            end
            fts = mat2xts(datenum(ret.date),ret.value,ret.id);
            fts_data = fts2mat(fts);
            if iscell(fts_data)
                fts(cellfun(@isnumeric,fts_data)) = {''};
            end
        end
        
        function risk = calcrisk(portfolio,riskmodel)
            risk = nan(length(riskmodel.dates),1);
            [spf exposure specrisk] = alignfields(portfolio,riskmodel.exposure,riskmodel.specrisk,1);
            [spf exposure specrisk faccov] = aligndates(spf,exposure,specrisk,riskmodel.faccov,riskmodel.dates);
            for t=1:length(riskmodel.dates)
                pf = fts2mat(spf(t,:));
                pf(isnan(pf)) = 0;
                exp = squeeze(exposure(t,:,:));
                exp(isnan(exp)) = 0;
                spec = fts2mat(specrisk(t,:));
                spec(isnan(spec)) = 0;
                riskmat = exp * squeeze(faccov(t,:,:)) * exp' + spec' * spec; 
                risk(t) = sqrt(pf*riskmat*pf');
            end
        end
    end
end
