classdef TCRealized < TCModel
    properties
        arrival
        marketimpact
        vwapspread
        commission
        fee
        borrowcost
    end
    
    methods
        function o = TCRealized(id, varargin)
        % Usage
        %     o = TCRealized(id, owner);
        %     o = TCRealized(id, dates, aggid, isLive);
        % where
        %       id: the identifier of the model
        %    owner: an AXDataSet object
        %    dates: a vector of numerical dates
        %    aggid: universe id
        %  fixcost: required by sotred procedure loading data
        % currency: required by sotred procedure loading data
            o = o@TCModel(id, varargin{:});
            o.type = 'TCMRealized';
            if isa(o.owner,'AXDataSet')
                o.owner([o.id '.BUY']) = o.buycost;            
                o.owner([o.id '.SELL']) = o.sellcost;
                o.owner([o.id '.ARRIVAL']) = o.arrival;
                o.owner([o.id '.MARKETIMPACT']) = o.marketimpact;
                o.owner([o.id '.VWAPSPREAD']) = o.vwapspread;
                o.owner([o.id '.COMMISSION']) = o.commission;
                o.owner([o.id '.FEE']) = o.fee;
                o.owner([o.id '.BORROW']) = o.borrowcost;
            end
        end
        
        function export(o)
            %Realized Cost Model
            sids = o.secids;
            
            % Note: Cannot export to Axioma as TransactionCostModel does
            % not support negative slope.
            
%             idx = {{o.date}, sids};
%             bc = fts2mat(o.buycost(idx{:}));
%             sc = fts2mat(o.sellcost(idx{:}));
%             ar = fts2mat(o.arrival(idx{:}));
%             mi = fts2mat(o.marketimpact(idx{:}));
%             co = fts2mat(o.commission(idx{:}));
%             fe = fts2mat(o.fee(idx{:}));
%             
%             com.axiomainc.portfolioprecision.TransactionCostModel(o.ws, o.id, sids, ...
%                 bc, sc, com.axiomainc.portfolioprecision.Unit.CURRENCY);
%             
%             com.axiomainc.portfolioprecision.TransactionCostModel(o.ws, [o.id '_ARRIVAL'], sids, ...
%                 ar, ar, com.axiomainc.portfolioprecision.Unit.CURRENCY);
%             
%             com.axiomainc.portfolioprecision.TransactionCostModel(o.ws, [o.id '_MARKETIMPACT'], sids, ...
%                 mi, mi, com.axiomainc.portfolioprecision.Unit.CURRENCY);
%             
%             com.axiomainc.portfolioprecision.TransactionCostModel(o.ws, [o.id '_COMMISSION'], sids, ...
%                 co, co, com.axiomainc.portfolioprecision.Unit.CURRENCY);
%             
%             com.axiomainc.portfolioprecision.TransactionCostModel(o.ws, [o.id '_FEE'], sids, ...
%                 fe, fe, com.axiomainc.portfolioprecision.Unit.CURRENCY);           
        end
    end
    
    methods (Access = protected)
        function o = load(o)
        % Fill buybreak, buycost, sellbreak, sellcost
            aggid = sprintf(',%s',o.aggid{:});
            aggid = aggid(2:end);
            dates = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},o.dates);
            tstr = sprintf(',%s',dates{:});
            tstr = tstr(2:end);

            TCM = DB('QuantTrading').runSql('axioma.GetCostEstimate',aggid,tstr,o.owner.isLive);
            dates = datenum(TCM.Date);
            secid = TCM.SecId;
            o.arrival = mat2xts(dates, TCM.Arrival, secid);
            o.marketimpact = mat2xts(dates, TCM.MarketImpact, secid);
            o.vwapspread = mat2xts(dates, TCM.VwapSpread, secid);
            o.commission = mat2xts(dates, TCM.Commission, secid);
            o.fee = mat2xts(dates, TCM.Fee, secid);
            o.borrowcost = mat2xts(dates, TCM.BorrowCost, secid);
            
            o.buybreak = mat2xts(dates, zeros(size(secid)), secid);
            o.buycost = o.arrival + o.marketimpact + o.commission + o.fee;
            o.sellbreak = o.buybreak;
            o.sellcost  = o.buycost;
        end
    end
end

    