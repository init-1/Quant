classdef AXRebalancing < Exportable
    properties
        DBID = NaN;  % related to database, double; if no DB involved, just ignore it
        
        benchmarkId = 'BENCHMARK';
        roundlotsId = 'ROUNDLOTSIZE';
        accountId = '';
        alphaId   = '';
        prevalphaId = '';
        betaId = '';
        priceId   = '';
        riskmodelId = '';
        tcmodelId   = '';
        rcmodelId = '';
        cashflow = 0;
        minruntime = 1;
        maxruntime = 60;
        budgetsize = NaN;
        volumeId = '';
    end
    
    methods
        function o = AXRebalancing(id, varargin)
            o = o@Exportable(id, 'Reblancing');
            flds = varargin(1:2:end-1);
            vals = varargin(2:2:end);
            for i = 1:length(flds)
                o.(flds{i}) = upper(vals{i});
            end
        end
        
        function export(o)
            o.ws.setDefaultPriceGroup(o.ws.getGroup(o.priceId));
            initport = o.ws.getAccount(o.accountId);
            if isnan(o.budgetsize)
                refsize = initport.getReferenceSize;
            else
                refsize = o.budgetsize;
            end
            reb = o.ws.getRebalancing(o.id);
            if isempty(reb)
                TRACE(['    Creating Rebalancing ' o.id ' ... ']);
                reb = com.axiomainc.portfolioprecision.optimization.Rebalancing(o.ws, initport, o.id, o.id, o.ws.getDate());
                TRACE('done\n');
            else
                TRACE(['    Rebalancing ' o.id ' already exists\n']);
            end
            
            reb.setRiskModel(o.ws.getRiskModel(o.riskmodelId));
            reb.setBenchmark(o.ws.getGroup(o.benchmarkId));
            reb.setAlphaGroup(o.ws.getGroup(o.alphaId));
            reb.setNameCountCriterion(0.1, com.axiomainc.portfolioprecision.Unit.CURRENCY); %Min $ amount to be counted as holding
            reb.setRoundLotGroup(o.ws.getGroup(o.roundlotsId));
            reb.setTransactionCostModel(o.ws.getTransactionCostModel(o.tcmodelId));
            reb.setBudgetSize(o.cashflow + refsize);
            reb.setReferenceSize(o.cashflow + refsize);
            reb.setRunTimeMin(o.minruntime);
            reb.setRunTimeMax(o.maxruntime);
        end
    end
end