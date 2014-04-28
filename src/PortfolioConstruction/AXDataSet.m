classdef AXDataSet < handle % this class has a export() but not from Exportable since it's a handle
    properties (Constant)
        SEC_INFO = {'ticker',      'AssetMap',   Unit.TEXT,   'ticker'; ...
                    'roundLotSize','Group',      Unit.SHARES, 'roundLotSize'};
    end
    properties(SetAccess = private)
        isLive
        dates
        aggid
        
        universe   % type of Universe
        attribute  % a container.Map containing benchmark, accout, alpha and other myfints stuff, plus risk & tc model
    end

    methods
        function o = AXDataSet(isLive, dates, aggid)
            if ischar(aggid), aggid = {aggid}; end
            o.isLive = isLive;
            o.dates  = datenum(dates);
            o.aggid  = aggid;

            o.universe = Universe(isLive, dates, aggid);  % load universe
            o.attribute = containers.Map('KeyType', 'char', 'ValueType', 'any');

            for i = 1:length(o.aggid)
                o.add(['X' o.aggid{i}], loadBenchmark(o, o.aggid{i}), 'BENCHMARK');
            end
            
            secinfo = o.loadSecMstr;
            o.add('TICKER',       secinfo.ticker,       'ASSETMAP');
            o.add('ROUNDLOTSIZE', secinfo.roundLotSize, 'GROUP');
        end
        
        function fts = loadBenchmark(o, aid)
            secids = o.getUniverse;
            weight = NaN(size(o.universe));
            for t = 1:length(o.dates)
                data = DB('QuantTrading').runSql('axioma.GetIndexHolding', ...
                       aid, datestr(o.dates(t),'yyyy-mm-dd'), o.isLive, 100);
                [tf, posn] = ismember(data.SecId, secids);
                if any(tf==0)
                    TRACE.Warn([num2str(length(posn(tf==0))) ' secid(s) will be removed from benchmark on ' datestr(o.dates(t),'yyyy-mm-dd') '\n']);
                end
                posn(tf==0) = []; 
                weight(t,posn) = data.Weight(tf~=0);
            end
            fts = myfints(o.dates, weight, secids);
            fts.unit = Unit.PERCENT;
        end

        function ftses = loadSecMstr(o)
            items = o.SEC_INFO;
            secids = o.getUniverse;     
            fields = sprintf(',%s', items{:,4});
            idlist = sprintf(',''%s''', secids{:});
            data = DB.runSql(['select id' fields ' from QuantStaging.dbo.SecMstr where id in (' idlist(2:end) ')']);
            [tf, posn] = ismember(secids, data.id);
            T = length(o.dates);
            for i = 1:size(items,1)
                 fts = myfints(o.dates, repmat(data.(items{i,1})(posn(tf))',T,1), secids(tf));
                 fts.unit = items{i,3};
                 ftses.(items{i,1}) = fts;
            end
        end
        
        function fts = loadSecTS(o, itemid, backfilldays, unit)
            sdate = datestr(min(o.dates)-100, 'yyyy-mm-dd');
            edate = datestr(max(o.dates)+100, 'yyyy-mm-dd');

            fts = LoadQSSecTS(o.getUniverse, itemid, 0, sdate, edate);
            fts = backfill(fts, backfilldays, 'entry');
            fts.unit = unit;
            fts.freq = 'D';
        end
        
        function fts = loadRawTS(o, itemid, backfilldays, unit)
            sdate = datestr(min(o.dates)-100, 'yyyy-mm-dd');
            edate = datestr(max(o.dates)+100, 'yyyy-mm-dd');
            
            fts = LoadRawItemTS(o.getUniverse, itemid, sdate, edate);
            fts = backfill(fts, backfilldays, 'entry');
            fts.unit = unit;
            fts.freq = 'D';
        end
        
        function fts = loadFactor(o, facid, backfilldays, unit)
            if nargin < 4
                unit = Unit.NUMBER;
            end
            sdate = datestr(min(o.dates)-5*backfilldays, 'yyyy-mm-dd');
            edate = datestr(max(o.dates)+5*backfilldays, 'yyyy-mm-dd');
            
            if o.isLive
                fts = LoadFactorTSProd(o.getUniverse, facid, sdate, edate, o.isLive);
            else
                fts = LoadFactorTS(o.getUniverse, facid, sdate, edate, o.isLive);
            end
            fts = backfill(fts, backfilldays, 'entry');
            fts.unit = unit;
            fts.freq = 'D';
        end  

        function fts = loadAlpha(o, strategyid)
            dates_ = [];
            secid = {};
            value = [];
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                ret = DB('QuantTrading').runSql('axioma.GetAlpha',strategyid, tstr);
                dates_ = [dates_; repmat(o.dates(t), length(ret.Id), 1)]; %#ok<AGROW>
                secid = [secid; ret.Id]; %#ok<AGROW>
                value = [value; ret.Value]; %#ok<AGROW>
            end
            fts = mat2xts(dates_, value, secid);
            fts.unit = Unit.NUMBER;
        end
        
        function o = addAccountRestricted(o,prefix,accList)
        %% Restricted List
            if nargin < 2
                prefix = 'RSACT';
            end
            if nargin < 3
                ret = DB('QuantTrading').runSql('axioma.GetRestrictedAccounts');
                accList = ret.Id;
            end

            DB('QuantPosition');
            for i = 1:numel(accList)
                resList = {};
                dates_ = []; 
                for t = 1:length(o.dates)
                    tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                    try
                        ret = DB.runSql('dbo.GetRestrictedList', 2, accList{i}, tstr);
                        if ischar(ret.secid)
                            n = 1;
                        else
                            n = length(ret.secid);
                        end
                        dates_ = [dates_; repmat(o.dates(t),n,1)]; %#ok<AGROW>
                        resList = [resList; ret.secid]; %#ok<AGROW>
                    catch %#ok<CTCH>
                    end
                end
                fts = mat2xts(dates_, ones(size(dates_)), resList);
                o.add([prefix '_' accList{i}], fts, 'GROUP');
            end
        end

        function o = addCustomRestricted(o,prefix,cusType,typeName)
            if nargin < 2
                prefix = 'RSCUS';
            end
            if nargin < 3
                cusType = {'Custom - Benchmark','Custom - Do Not Trade','Custom - Do Not Hold','Global Restriction','AP Restriction'};
                typeName = {'Benchmark','DNT','DNH','Global','AP'};
            end
            
            DB('QuantTrading');
            for i = 1:numel(cusType)
                resList = {};
                dates_ = []; 
                for t = 1:length(o.dates)
                    tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                    try
                        ret = DB.runSql('axioma.GetCustomRestrictedList',cusType{i},tstr);
                        if ischar(ret.SecId)
                            n = 1;
                        else
                            n = length(ret.SecId);
                        end
                        dates_ = [dates_; repmat(o.dates(t),n,1)]; %#ok<AGROW>
                        resList = [resList; ret.SecId]; %#ok<AGROW>
                    catch %#ok<CTCH>
                    end
                end
                fts = mat2xts(dates_, ones(size(dates_)), resList);
                fts.desc = cusType{i};
                o.add([prefix '_' typeName{i}], fts, 'GROUP');
            end
        end
    
        function o = addAccount(o, id, strategyid, acctid)
            if nargin < 3, acctid = 'All'; end
            dates_ = [];
            secid = {};
            shares = [];
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                ret = DB('QuantPosition').runSql('dbo.GetStrategyPositions', 1, acctid, strategyid, tstr);
                dates_ = [dates_; repmat(o.dates(t), length(ret.secid), 1)]; %#ok<AGROW>
                secid = [secid; ret.secid]; %#ok<AGROW>
                shares = [shares; ret.shares]; %#ok<AGROW>
            end
            fts = mat2xts(dates_, shares, secid);
            fts.unit = Unit.SHARES;
            o.add(id, fts, 'ACCOUNT');
        end
    
        function o = addAlpha(o, id, strategyid)
            fts = o.loadAlpha(strategyid);
            o.add(id, fts, 'GROUP');
        end
        
        function o = add(o, id, obj, type)
            if isa(obj, 'xts')  % include objs that are AXAttr
                if nargin < 4  % not specified type
                    if isa(obj, 'AXAttr')
                        type = obj.type;
                    else
                        type = 'GROUP';
                    end
                end
                obj = AXAttr(id, obj, upper(type));
                id = obj.id;  % reflect possible changes in id in AXAttr
            else
                FTSASSERT(nargin == 3, 'Wrong number of args');
            end
            o.attribute(id) = obj;
        end
        
        function o = subsasgn(o, s, b)
            if strcmp(s(1).type,'()')
                FTSASSERT(length(s) == 1, 'Multiple level assignment not allowed');
                FTSASSERT(isa(b,'AXAttr') || isa(b,'Model') || isa(b,'xts'), 'Not allowed type of RHS');
                id = s(1).subs{:};
                o = add(o, id, b);
            else
                o = builtin('subsasgn', o, s, b);
            end
        end

        function o = subsref(o, s)
            if strcmp(s(1).type,'()')
                FTSASSERT(length(s) == 1, 'Multiple level reference not allowed');                
                id = s(1).subs{:};
                o = o.attribute(id);
            else
                o = builtin('subsref', o, s);
            end
        end
        
        function ids = keys(o, dates)
        % type should be sth like 'GROUP', 'METAGROUP', 'SET', 'TEXTGROUP', etc.
            if nargin < 2, dates = o.dates; end
            vals = values(o);
            ids = {};
            for v = vals
                if isa(v{:}, 'AXAttr')
                    ids = [ids; getIds(v{:}, dates)]; %#ok<AGROW>
                else  % like RiskModel, TCModel
                    ids = [ids; v{:}.id]; %#ok<AGROW>
                end
            end
        end
        
        function sids = getUniverse(o, varargin)
        % varargin should be dates if provided, otherwise it's all dates in the universe
            sids = getUniverse(o.universe, varargin{:});
        end
        
        function fts = applyUniverse(o, fts)
            fts = applyUniverse(o.universe, fts);
        end
        
        function o = trimUniverse(o, fts)
        % Note that fts must be of logical
            o.universe = trimUniverse(o.universe, fts);
        end
        
        function st = getSelectionTypeLocally(o, id)
            st = AXSelection.UNKNOWN;
            subid = '';
            if ~ismember(id, keys(o.attribute))
                [id, subid] = strtok(id, '.');
                if isempty(subid) || ~ismember(id, keys(o.attribute))
                    return;
                end
            end

            st = getSelectionTypeLocally(o.attribute(id), subid(2:end));
        end
        
        function vals = values(o, type)
        % type should be sth like 'GROUP', 'METAGROUP', 'SET', 'TEXTGROUP', etc,
        %    or '~GROUP', '~METAGROUP', '~SET', '~TEXTGROUP', etc
            vals = values(o.attribute);
            if nargin < 2 || isempty(type), return; end
            
            if type(1) == '~'
                type(1) = [];
                flip = true;
            else
                flip = false;
            end
            
            n = length(vals);
            tf = false(1,n);
            for i = 1:n
                if strcmpi(vals{i}.type, type)
                    tf(i) = true;
                end
            end
            if flip, tf = ~tf; end
            vals = vals(tf);
        end
        
        function export(o)
            export(o.universe);
            vals = values(o);
            st = zeros(size(vals));
            for i = 1:length(vals)
                if strcmpi(vals{i}.type, 'COLLECTION')
                    st(i) = 1;
                elseif strcmpi(vals{i}.type, 'SET')
                    st(i) = 2;
                end
            end
            vals = [vals(st==0) vals(st==1) vals(st==2)]; % SET may contain COLLECTIONs
            for i = 1:length(vals)
                export(vals{i});
            end
        end
    end
end

