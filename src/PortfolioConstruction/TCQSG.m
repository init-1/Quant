classdef TCQSG < TCModel
    methods
        function o = TCQSG(id, varargin)
        % Usage
        %     o = TCMQSG(id, owner, fixcost, currency);
        %     o = TCMQSG(id, dates, aggid, isLive, fixcost, currency);
        % where
        %       id: the identifier of the model
        %    owner: an AXDataSet object
        %    dates: a vector of numerical dates
        %    aggid: universe id
        %  fixcost: required by sotred procedure loading data
        % currency: required by sotred procedure loading data
            o = o@TCModel(id, varargin{:});
            o.type = 'TCMPiecewise';
        end
    end
    
    methods (Access = protected)
        function o = load(o, fixcost, currency)
        % Fill buybreak, buycost, sellbreak, sellcost
            secid = {};
            buy_sell = {};
            break_cost = {};
            value = [];
            dates_ = [];
            no = [];
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                aggid = sprintf(',%s',o.aggid{:});
                aggid = aggid(2:end);
                
                ret = DB('QuantTrading').runSql('axioma.GetTCost', ...
                     'qsg', aggid, tstr, fixcost, 'SecId', currency, o.owner.isLive);

                fn = fieldnames(ret);
                fn(strcmp(fn, 'Id')) = [];
                buyBreakfield = fn(42:2:end-1);
                buyCostfield = fn(43:2:end);
                sellBreakfield = fn(42:-2:2);
                sellCostfield = fn(41:-2:1);
                
                n = length(ret.Id);
                for i = 1:length(buyBreakfield)
                    value = [value; ret.(buyBreakfield{i})]; %#ok<*AGROW>
                    buy_sell = [buy_sell; repmat({'buy'}, n, 1)];
                    break_cost = [break_cost; repmat({'break'}, n, 1)];
                    
                    value = [value; ret.(buyCostfield{i})];
                    buy_sell = [buy_sell; repmat({'buy'}, n, 1)];
                    break_cost = [break_cost; repmat({'cost'}, n, 1)];

                    value = [value; ret.(sellBreakfield{i})];
                    buy_sell = [buy_sell; repmat({'sell'}, n, 1)];
                    break_cost = [break_cost; repmat({'break'}, n, 1)];

                    value = [value; ret.(sellCostfield{i})];
                    buy_sell = [buy_sell; repmat({'sell'}, n, 1)];
                    break_cost = [break_cost; repmat({'cost'}, n, 1)];

                    secid = [secid; repmat(ret.Id, 4, 1)];
                    dates_ = [dates_; repmat(o.dates(t), 4*n, 1)];
                    
                    no = [no; ones(4*n,1)*i];
                end
            end
            
            xts5d = mat2xts(dates_, value, secid, no, break_cost, buy_sell);
            o.buybreak = xts5d(:,:,:,'break','buy');
            o.buycost  = xts5d(:,:,:,'cost','buy');
            o.sellbreak = xts5d(:,:,:,'break','sell');
            o.sellcost  = xts5d(:,:,:,'cost','sell');
        end
    end
end

    