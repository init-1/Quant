classdef TCFlat < TCModel
    methods
        function o = TCFlat(id, varargin)
        % Usage
        %     o = TCMFlat(id, owner, fixcost, currency);
        %     o = TCMFlat(id, dates, aggid, isLive, fixcost, currency);
        % where
        %       id: the identifier of the model
        %    owner: an AXDataSet object
        %    dates: a vector of numerical dates
        %    aggid: universe id
        %  fixcost: required by sotred procedure loading data
        % currency: required by sotred procedure loading data
            o = o@TCModel(id, varargin{:});
            o.type = 'TCMLinear';
            if isa(o.owner,'AXDataSet')
                o.owner([o.id '.BUY']) = o.buycost;            
                o.owner([o.id '.SELL']) = o.sellcost;
            end
        end
        
        function export(o)
            %Linear Model
            sids = o.secids;
            idx = {{o.date}, sids};
            bc = fts2mat(o.buycost(idx{:}));
            sc = fts2mat(o.sellcost(idx{:}));
            
            com.axiomainc.portfolioprecision.TransactionCostModel(o.ws, o.id, sids, ...
                bc, sc, com.axiomainc.portfolioprecision.Unit.CURRENCY);
        end
    end
    
    methods (Access = protected)
        function o = load(o, fixcost, currency)
        % Fill buybreak, buycost, sellbreak, sellcost
            secid = {};
            dates_ = [];
            bk = [];
            ct = [];
            aggid = sprintf(',%s',o.aggid{:});
            aggid = aggid(2:end);
            
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                TCM = DB('QuantTrading').runSql('axioma.GetTCost', ...
                     'flat', aggid, tstr, fixcost, 'SecId', currency, o.owner.isLive);
                dates_ = [dates_; repmat(o.dates(t), length(TCM.Id), 1)]; %#ok<*AGROW>
                secid = [secid; TCM.Id];
                bk = [bk; TCM.Break];
                ct = [ct; TCM.Cost];
            end

            o.buybreak = mat2xts(dates_, bk, secid);
            o.buycost = mat2xts(dates_, ct, secid);
            o.sellbreak = o.buybreak;
            o.sellcost  = o.buycost;
        end
    end
end

    