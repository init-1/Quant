classdef TCModel < Model
    properties
        buybreak
        buycost
        sellbreak
        sellcost
    end
    
    methods
        function o = TCModel(id, varargin)
        % This is abstract class. The subclass should used like this:
        %     o = TCMModel(id, owner, fixcost, currency);
        %     o = TCMModel(id, dates, aggid, isLive, fixcost, currency);
        % where
        %       id: the identifier of the model
        %    owner: an AXDataSet object
        %    dates: a vector of numerical dates
        %    aggid: universe id
        %  fixcost: required by sotred procedure loading data
        % currency: required by sotred procedure loading data
            o = o@Model(id, varargin{:});
        end
        
        function export(o)
            %Piecewise Linear Model
            sids = o.secids;
            idx = {{o.date}, sids, ':'};
            bb = squeeze(o.buybreak(idx{:}));
            bc = squeeze(o.buycost(idx{:}));
            sb = -squeeze(o.sellbreak(idx{:}));
            sc = squeeze(o.sellcost(idx{:}));
            
            sdf = java.text.SimpleDateFormat('yyyy-mm-dd');
            TCM = com.axiomainc.portfolioprecision.TransactionCostModel(o.ws, o.id, o.id, ...
                  sdf.parse(datestr(o.date,'yyyy-mm-dd')), com.axiomainc.portfolioprecision.Unit.CURRENCY);
            for i = 1:length(sids)
                coststruct = com.axiomainc.portfolioprecision.CostStructure(TCM, sids{i}, sids{i});
                coststruct.includeAsset(o.ws.getAsset(sids{i}));

                for k = 1:size(bc,2)
                    coststruct.addBuySlope(bb(i,k), bc(i,k));
                end
                % in case number of buy bins do not equal number of sell bins, loop separately
                for k = 1:size(sc,2)
                    coststruct.addSellSlope(sb(i,k), sc(i,k));
                end
            end
        end
    end
end

    