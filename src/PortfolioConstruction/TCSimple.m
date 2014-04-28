classdef TCSimple < TCModel
    methods
        function o = TCSimple(id, varargin)
        % Usage
        %     o = TCMSimple(id, owner, fixcost, currency);
        %     o = TCMSimple(id, dates, aggid, isLive, fixcost, currency);
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
            bkfld = {};
            ctfld = {};
            dates_ = [];
            bk = [];
            ct = [];
            aggid = sprintf(',%s',o.aggid{:});
            aggid = aggid(2:end);
            
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                ret = DB('QuantTrading').runSql('axioma.GetTCost', ...
                     'simple', aggid, tstr, fixcost, 'SecId', currency, o.owner.isLive);

                fn = fieldnames(ret);
                breakfield = fn(strncmpi(fn, 'Brea', 4));
                costfield = fn(strncmpi(fn, 'Cost', 4));  % costfield must correspond to breakfield in number
                n = length(ret.Id);
                for i = 1:length(breakfield)
                    bk = [bk; ret.(breakfield{i})]; %#ok<*AGROW>
                    ct = [ct; ret.(costfield{i})];
                    secid = [secid; ret.Id];
                    bkfld = [bkfld; repmat(breakfield(i), n, 1)];
                    ctfld = [ctfld; repmat(costfield(i), n, 1)];
                    dates_ = [dates_; repmat(o.dates(t), n, 1)];
                end
            end
            
            o.buybreak = mat2xts(dates_, bk, secid, bkfld);
            o.buycost  = mat2xts(dates_, ct, secid, ctfld);
            o.sellbreak = o.buybreak;
            o.sellcost  = o.buycost;
        end
    end
end

    