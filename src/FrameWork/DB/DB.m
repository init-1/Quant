classdef DB
    properties (Constant) %, GetAccess = private)
        DATE_FMT = 'yyyy-mm-dd';
        ITEM_MAP = initMap;
        SOURCE   = 'QAI'; % QAI' or 'CIQ'
        DATE_DIFF = 693962; % difference between MS-SQL dates and Matlab dates (Mat > SQL)
    end
    
    properties (Access = private)
        DBName
    end
    
    properties  %%% tracking facilities here.
        currentDumpFile = '';
    end
    
    methods
        function o = DB(dbname)
            o.DBName = dbname;
        end
        
        function ret = runSql(o, spname, varargin)
            ret = runSP(o.DBName, spname, varargin);
            if nargout > 0 && isempty(ret)
                throw(MException('LOADDATA:NODATA', ['No data in DB for query ''' spname '''']));
            end
        end
        
        function o = setDumpFile(o, dfile)
            o.currentDumpFile = dfile;
        end

        function dump(o, varargin)  % list of variable names to be dumped
            if isempty(o.currentDumpFile)
                return;
            end
            if ~exist(o.currentDumpFile, 'file')
                eval([varargin{1} '= varargin{2};']);
                save(o.currentDumpFile, varargin{1});
                varargin(1:2) = [];
            end
            for i = 1:2:length(varargin)
                eval([varargin{i} '= varargin{i+1};']);
                save(o.currentDumpFile, varargin{i}, '-append');
            end
        end
    end 
       
    methods (Static)
        function pit = LoadPIT(secids, itemid, startDate, endDate, nQtrs)
            if ischar(secids), secids = {secids}; end
            pit = cell(nQtrs,1);
            
            if strncmp(itemid, 'D0020', 5)  % not CIQ PIT, get use dataqa.usp_getpit
                o = DB('DataQA');
                seclist = sprintf(',E%s', secids{:});
                ret = o.runSql('api.usp_getPIT' ...
                    , itemid ...
                    , seclist(2:end) ...
                    , datestr(datenum(startDate)-nQtrs*95, o.DATE_FMT) ...
                    , datestr(endDate, o.DATE_FMT) ...
                    , '');
                %idx = str2double(ret.QtrsBack) < nQtrs; % with this filter even drag down the performance
                ret.Secid = cellfun(@(x){x(2:end)}, ret.Secid);
                p = mat2xts(ret.date, ret.targetval, ret.Secid, ret.QtrsBack);
                for i = 0:nQtrs-1
                    pit{i+1} = p(:,:,num2str(i));
                end
                return;
            end
            
            o = DB('DataCache'); % using SP from DataCache
            partition = 1:100:length(secids);
            if partition(end) <= length(secids)
                partition = [partition length(secids)+1];
            end
            for k = 1:length(partition)-1
                secids_part = secids(partition(k):partition(k+1)-1);
                if isItemCached(itemid)
                    seclist = sprintf(',''E%s''', secids_part{:});
                    ret = o.runSql(['select secid as id,cast(filingDate as int) filingDate,' ...
                        ' cast(periodendDate as int) periodendDate, QtrN, dataitemValue' ...
                        ' from api.ciqfilingdata' ...
                        ' where secid in (' seclist(2:end) ')' ...
                        ' and filingdate between ' ...
                        num2str(datenum(startDate)-nQtrs*95-DB.DATE_DIFF) ' and '...
                        num2str(datenum(endDate)-nQtrs*95-DB.DATE_DIFF) ' and' ...
                        ' dataitemid=''' itemid '''' 'order by id,filingDate']);
                else
                    seclist = sprintf(',E%s', secids_part{:});
                    ret = o.runSql('api.usp_getCIQFilingData' ...
                        , datestr(datenum(startDate)-nQtrs*95, o.DATE_FMT) ...
                        , datestr(endDate, o.DATE_FMT) ...
                        , seclist(2:end) ...
                        , itemid);
                end
                
                ret.filingDate = ret.filingDate + DB.DATE_DIFF;
                ret.periodendDate = ret.periodendDate + DB.DATE_DIFF; % we don't use periodendDate currently
                ret.QtrN = double(ret.QtrN);
                
                %% Order the result returned from SQL by filingDate first QtrN second
                %  to make sure the max QtrN for the same filingDate enters currentQtr and currentPeriodDate.
                %  x dones not depend on this sorting but we want to avoid calling unique(.) more times
                [~,idx] = sortrows([ret.filingDate, ret.QtrN], [1 2]);
                [fdate,~,date_sub] = unique(ret.filingDate(idx));
                [secids_part,~,sec_sub] = unique(ret.id(idx));
                [qtrfld,~,qtr_sub] = unique(ret.QtrN(idx));
                T = numel(fdate);
                N = numel(secids_part);
                S = numel(qtrfld);  % by convention, T,S used for time, N,M for others
                secids_part = cellfun(@(x){x(2:end)}, secids_part);
                
                % Put all data into a multi-dimentional matrix so we can easily index them
                x = nan(T,N,S);
                ind = sub2ind([T,N,S], date_sub, sec_sub, qtr_sub);
                x(ind) = ret.dataitemValue(idx);
                
                ind = sub2ind([T,N], date_sub, sec_sub);
                currentQtr = nan(T,N);
                currentQtr(ind) = ret.QtrN(idx);
                currentPeriodDate = nan(T,N);
                currentPeriodDate(ind) = ret.periodendDate(idx);
                
                % backfill x
                nanloc = find(isnan(x));
                [nanline,~] = ind2sub([T N*S], nanloc);
                nanloc(nanline == 1) = [];  % first row we can not backfill because no further backward
                for i = 1:numel(nanloc)
                    x(nanloc(i)) = x(nanloc(i)-1);
                end
                
                % get latest available quater no.
                for t = 2:T
                    [currentQtr(t,:),idx] = max(currentQtr(t-1:t,:),[],1);
                    currentPeriodDate(t,idx==1) = currentPeriodDate(t-1,idx==1);
                    currentQtr(t, fdate(t) - currentPeriodDate(t,:) > 360) = NaN; % too far away from filingdate
                end
                
                d1 = repmat(1:T,1,N);
                d2 = kron(1:N,ones(1,T));
                x(:,:,S+1) = NaN;    % expanding a panel to be used below
                for i = 1:nQtrs
                    [tf,loc] = ismember(currentQtr(:)-i+1, qtrfld);
                    loc(~tf) = S+1;  % those no qtr found point to the NaN panel
                    idx = sub2ind([T N S+1], d1, d2, loc');
                    mat = nan(T,N);
                    mat(:) = x(idx);
                    fts = myfints(fdate, mat, secids_part);
                    if isempty(pit{i})
                        pit{i} = fts;
                    else
                        [fts, pit{i}] = aligndates(fts, pit{i}, unique([fdate; pit{i}.dates]));
                        pit{i} = [pit{i} fts];
                    end
                end
            end
        end
        
        function ts = LoadTS(secids, itemids, startDate, endDate)
            if ischar(itemids), itemids = {itemids}; end
            itemlist = sprintf(',''%s''', itemids{:});
            o = DB('DataQA');
            ret = o.runSql(['select returnType from api.itemmstr where id in (' itemlist(2:end) ')']);
            numTypeIdx = strcmpi(ret.returnType, 'number');
            
            cachedIdx = cellfun(@(x) isItemCached(x), itemids);
            
            if any(cachedIdx)
                seclist  = sprintf(',''E%s''', secids{:}); % quoted
                sql = '';
                if any(cachedIdx & numTypeIdx)
                    numitemlist = sprintf(',''%s''', itemids{cachedIdx & numTypeIdx});
                    sql = [...
                    'select itemid, secid, date, numvalue value from api.ts' ...
                    ' where date between ' datestr(startDate, ['''' o.DATE_FMT '''']) ...
                    ' and ' datestr(endDate, ['''' o.DATE_FMT '''']) ...
                    ' and itemid in (' numitemlist(2:end) ')' ...
                    ' and secid  in (' seclist(2:end) ')'];
                end
                if any(cachedIdx & ~numTypeIdx)
                    dateitemlist = sprintf(',''%s''', itemids{cachedIdx & ~numTypeIdx});
                    if ~isempty(sql), sql = [sql ' union ']; end
                    sql = [sql ...
                    'select itemid, secid, date, cast(cast(strvalue as datetime) as int)+' num2str(o.DATE_DIFF) ' value from api.ts' ...
                    ' where date between ' datestr(startDate, ['''' o.DATE_FMT '''']) ...
                    ' and ' datestr(endDate, ['''' o.DATE_FMT '''']) ...
                    ' and itemid in (' dateitemlist(2:end) ')' ...
                    ' and secid  in (' seclist(2:end) ')'];
                end
                 
                o = DB('DataCache');
                ret = o.runSql(sql);
            else
                ret = struct('date', [], 'secid', [], 'value', [], 'itemid', []);
            end
            
            items = itemids(~cachedIdx);
            if ~isempty(items)
                o = DB('DataQA');
                seclist = sprintf(',E%s', secids{:}); % non-quoted
                for i = 1:length(items)
                    ret2 = o.runSql('api.usp_GetTS', items{i} ...
                         , seclist(2:end) ...
                         , datestr(startDate, o.DATE_FMT) ...
                         , datestr(endDate, o.DATE_FMT) ...
                         , '', 0, '', '');
                    if ischar(ret2.targetval) || iscell(ret2.targetval)
                        ret2.targetval = datenum(ret2.targetval);
                    end
                    
                    if ischar(ret2.date), ret2.date = {ret2.date}; end
                    if ischar(ret2.secid), ret2.secid = {ret2.secid}; end
                    
                    ret.date = [ret.date; ret2.date];
                    ret.secid = [ret.secid; ret2.secid];
                    ret.value = [ret.value; ret2.targetval];
                    ret.itemid = [ret.itemid; repmat(items(i), length(ret2.date),1)];
                end
            end           
            
            ret.secid = cellfun(@(x){x(2:end)}, ret.secid);
            ts = mat2xts(ret.date, ret.value, ret.secid, ret.itemid);
            ts = padfield(ts, secids);
        end
    end
    
    methods (Static)
        function fts = load(db_fun, ids, alignedIds, targetFreq)
            if nargin < 4 || isempty(strtrim(targetFreq))
                targetFreq = 'NULL';
            else
                targetFreq = targetFreq(1);
            end
            
            if ischar(ids), ids = {ids}; end
            
            idList = sprintf(',%s', ids{:});
            ret = db_fun(idList(2:end), targetFreq);
            
            % Take care of the case in which the vecData are date strings
            if ischar(ret.TargetVal)
                ret.TargetVal = {ret.TargetVal};
            end

            if iscell(ret.TargetVal)
                ret.TargetVal = datenum(ret.TargetVal);
            end
            
            fts = mat2xts(ret.DataDate, ret.TargetVal, ret.SecId);
            
            if ~strcmpi(targetFreq, 'NULL')
                fts = aligndates(fts, targetFreq);
            end
            if ~isempty(alignedIds)
                fts = padfield(fts, alignedIds);
            end
        end
        
        function itemTS = loadRawItemTS(secids, itemid, startDate, endDate, targetFreq)
        % Syntax:
        %    itemTS = LoadRawItemTS(secIds, itemId, startDate, endDate, targetFreq)
        % NOTE We write targetFreq as varargin to make it optional.
        %
        % EVERY DATA ITEM IS ASSOCIATED WITH A FREQUENCY AND REGISTERED IN ITEM.ITEMMSTR TABLE.
        % HOWEVER, THAT REGISTERED IS HIGHLY UNRELIABLE. 
        % WE USE THE FREQ in DB.ITEM_MAP INSTEAD.
            [tf,loc] = ismember(itemid, DB.ITEM_MAP(:,2));
            if strcmpi(DB.SOURCE, 'QAI') || ~tf
                itemTS = DB.LoadTS(secids, itemid, startDate, endDate);
            else
                freq = freqnum(DB.ITEM_MAP{loc,1});
                pattern = '\<D00.......\>';
                fstr = DB.ITEM_MAP{loc,3};
                if isa(fstr, 'function_handle')
                    fstr = regexprep(func2str(fstr), '^@\(\<D00.......\>\)', '');
                end
                [~,~,~,ids] = regexp(fstr, pattern);
                fts = cell(numel(ids),1);
                for i = 1:numel(ids)
                    fts{i} = DB.LoadTS(secids, ids{i}, startDate, endDate);
                end
                
                if freq ~= 0
                    dates = genDateSeries(fts{i}.dates(1), endDate, freq);
                    [fts{:}] = aligndates(fts{:}, dates);
                    idx = true(size(fts{1}));
                    for i = 1:numel(fts)
                        idx_ = isnan(fts2mat(fts{i}));
                        fts{i}(idx_) = 0;
                        idx = idx & idx_;
                    end
                    for i = 1:numel(fts)
                        fts{i}(idx) = NaN;
                    end
                end
                
                if isa(DB.ITEM_MAP{loc,3}, 'function_handle')
                    fun = DB.ITEM_MAP{loc,3};
                else
                    arglist = sprintf(',%s', ids{:});
                    fun = str2func(['@(' arglist(2:end) ')' DB.ITEM_MAP{loc,3}]);
                end
                itemTS = fun(fts{:});
                itemTS(isinf(itemTS)) = NaN;
                
                if freq >= freqnum('M') % freq must be 'M', 'Q', 'S', 'A'
                    dates = genDateSeries(itemTS.dates(1), endDate, 'M');  % take 'M' as base frequency. Must include endDate
                    itemTS = aligndata(itemTS, dates);
                    if freq == freqnum('A')
                        fillPeriods = 18;
                    elseif freq == freqnum('Q')
                        fillPeriods = 6;
                    elseif freq == freqnum('M')
                        fillPeriods = 2;
                    else
                        fillPeriods = 0;
                    end
                    itemTS = fill(itemTS, fillPeriods, 'entry');
                end
            end

            if nargin > 4  % targetFreq provided
                dates = genDateSeries(startDate, endDate, targetFreq);
                itemTS = aligndates(itemTS, dates);
            else
                itemTS = itemTS([startDate '::' endDate],:);
            end 
        end

        function fts = loadFactorTS(secIds, factorId, startDate, endDate, isLive, freq, isOnTheFly, dateBasis)
        % Syntax:
        %     factorTS = loadFactorTS(secIds, factorId, startDate, endDate, isLive, [targetFreq], [dateBasis])
        % NOTE targetFreq and dateBasis are optional.
            finfo = LoadFactorInfo({factorId}, {'MatlabFunction','name','higherTheBetter','desc_','factortypeid'});
            if isdeployed
                classFun = @FacBase;
            else
                classFun = str2func(finfo.MatlabFunction);
            end

            if nargin > 6 && isOnTheFly  % freq must be provided
                db = setDumpFile(DB(''), ['DUMP-' factorId '.mat']);
                if nargin > 7
                    fts = create(classFun(), false, freq, secIds, startDate, endDate, dateBasis);  % we DONT use isLive flag if generating on the fly
                else
                    fts = create(classFun(), false, freq, secIds, startDate, endDate);  % we DONT use isLive flag if generating on the fly
                end
                db.dump('factor', fts);
            else
                db_fun = @(secIdList, targetFreq) runSql(DB('QuantStrategy'),'fac.GetFactorTS',factorId,secIdList,startDate,endDate,targetFreq,isLive);
                if nargin > 5 % freq is provided
                    fts = DB.load(db_fun, secIds, secIds, freq);
                else
                    fts = DB.load(db_fun, secIds, secIds);
                end
            end
            
            fts = create(classFun(), fts ...
                , 'id',              factorId ...
                , 'name',            finfo.name ...
                , 'higherTheBetter', finfo.higherTheBetter ...
                , 'desc',            finfo.desc_ ...
                , 'type',            finfo.factortypeid ...
                , 'isLive',          isLive);
        end
    end
end

function m = initMap
    worldScope2CIQ = {...
    %%% World Scope to CIQ
    'D', 'D000110013', 'D001200009' ...
    'D', 'D000110018', 'D000550104' ...
    'D', 'D000110087', 'D000551600' ...
    'D', 'D000110101', 'D000551601 / D001200009' ...
    'Y', 'D000110113', 'D000550104' ...
    'Y', 'D000110115', 'D000563219 * 1e6' ...
    'Y', 'D000110142', 'D000550551 / D000563214' ...
    'Y', 'D000110146', 'D000550068' ...
    'Y', 'D000110162', 'D000550068' ...
    'Y', 'D000110193', 'D000550067' ...
    'Y', 'D000110211', 'D000550067' ...
    'Y', 'D000110237', 'D000550029 / D000563214' ...
    'Y', 'D000110329', 'D000550541 * (-1e6)' ...
    'Y', 'D000110343', 'D000550855 * (-1e6)' ...
    'Y', 'D000110365', 'D000550430 * 1e6' ...
    'Y', 'D000110440', 'D000550068 / D000550067' ...
    'Y', 'D000110442', 'D000550068 / D000550067' ... 
    'Y', 'D000110466', @(D000550068) growth(D000550068,3) ...
    'Y', 'D000110467', @(D000550068) growth(D000550068,5) ...
    'Y', 'D000110473', 'D000550071 * 1e6' ...
    'Y', 'D000110479', @(D000550067) growth(D000550067,5) ...
    'Y', 'D000110514', 'D001200009 * D001200018 + D000548156 + D000554515 + D000555129 - D000554391' ...
    'Y', 'D000110538', '(D000549964 + D000550021 + D000549971 + D000550750 + D000550628 + D000550634 + D000550829 + D000550835 + D000550855) * 1e6' ...
    'Y', 'D000110578', '' ...
    'Y', 'D000110585', 'D000550551 * 1e6' ...
    'Y', 'D000110729', 'D000551308 / ftsmovfun(D000550326,2,@nanmean)' ...
    'Y', 'D000110842', 'D000549800 / D000551360 * 100' ...
    'Y', 'D000110852', @(D000551360) growth(D000551360,5) ...
    'Y', 'D000110891', @(D000549811) growth(D000549811,5) ...
    'Y', 'D000111021', 'D001200056 / D000581754' ...
    'Y', 'D000111048', '(D001200056 * D001200018) / D000581044' ...
    'Y', 'D000111132', 'D000550893 * 1e6' ...
    'Y', 'D000111154', 'D000550067 / ftsmovfun(D000550104,2,@nanmean) * 100' ...
    'Y', 'D000111158', '(D000549800 + ((-D000550295 - D000549899) * (1 - D000562779))) / ftsmovfun(D000550195 + D000550264,2,@nanmean) * 100' ...
    'Y', 'D000111193', 'D000550427 * 1e6' ...
    'Y', 'D000111205', 'D000550166 / D000550430 *100' ...
    'Q', 'D000111339', 'D000554938 / D000555605 * 100' ...
    'Q', 'D000111345', 'D001200009 / D000554389' ...
    'Q', 'D000111346', 'D000551601 / D001200009' ...
    'Q', 'D000111361', 'D000549410 / D000548869 * 100' ...
    'Q', 'D000111412', 'D000554816 * 1e6' ...
    'Q', 'D000111453', 'D000554324' ...
    'Q', 'D000111513', 'D000555605 * 1e6' ...
    'Q', 'D000111622', 'D000551600' ...
    'Q', 'D000111623', 'D000549289 / D000561271' ...
    'Q', 'D000111726', 'D000555129 / D000554819 * 100' ...
    'Q', 'D000111739', 'D001200009 * D001200018 + D000548156 + D000554515 + D000555129 - D000554391' ...
    'Q', 'D000112407', 'D000551604 * 1e6' ...
    'Q', 'D000112408', 'D000551605 * 1e6' ...
    'W', 'D000112587', 'D001200009' ...
    'M', 'D000112644', 'D000561276 * 1e6' ...
    ... % pricing items
    'D', 'D001410415', 'D001200056' ...
    'D', 'D001410419', 'D001200058' ...
    'D', 'D001410423', 'D001200059' ...
    'D', 'D001410472', 'D001200018' ...
    'D', 'D001410451', 'D001200018 * D001200056' ...
    ... % 'D', 'D001410446', 'D001200065' ...
    'D', 'D001410430', 'D001200019' ...
    ... % 'D', 'D001400028', 'D001200033' ...
    };   

    ibes2CIQ = {...
    'M' 'D000410126' 'aligndates(D001200009,D003512023-1)' ... % CIQ is daily, exactly matched to IBES one day before IBES dates
    'M' 'D000410138' 'D003500008' ... % CPS
    'M' 'D000410146' 'D003500013' ... % DPS
    'M' 'D000410178' 'D003500022' ... % EPS, normalized
    'M' 'D000410404' 'D003500541' ... % BPS, minor difference
    'M' 'D000410405' 'D003500542' ... % ditto
    'M' 'D000410406' 'D003500543' ... % ditto
    'M' 'D000410564' 'D003500631' ... % CPS, minor difference
    'M' 'D000410565' 'D003500632' ... % ditto
    'M' 'D000410566' 'D003500633' ... % ditto
    'M' 'D000410724' 'D003500781' ... % DPS, minor difference
    'M' 'D000410725' 'D003500782' ... % ditto
    'M' 'D000410726' 'D003500783' ... % ditto
    'M' 'D000411364' 'D003501051' ... % 'D003500991' ... % ditto
    'M' 'D000411365' 'D003501052' ... % 'D003500992' ... % ditto
    'M' 'D000411366' 'D003501053' ... % 'D003500993' ... % ditto
    'M' 'D000411369' 'D003509419' ... % most matched in value
    ''  'D000411374' 'aligndates(D003509884, D000411374.dates)' ... % EPS FY1 num down
    'M' 'D000411384' 'D003515993' ... % ? EPS FY1 num, CUSTOMIZED
    'M' 'D000411394' 'D003516028' ... % ? EPS FY1 num up, CUSTOMIZED
    'M' 'D000412644' 'D003501531' ... % FY1 sales median...
    'M' 'D000412645' 'D003501532' ... % FY2 sales median
    'M' 'D000412646' 'D003501533' ... % FY3 sales median
    'M' 'D000415172' 'D003509438' ... % mean of recommendation level
    'M' 'D000415179' 'D003512028' ... % FQ1 dates
    'M' 'D000415183' 'D003512026' ... % FY1 dates
    'M' 'D000415184' 'D003512027' ... % FY2 dates
    'M' 'D000415185' 'D003512027' ... % ? FY3 dates
    'M' 'D000431932' 'D003512024' ... % FQ0 dates
    'M' 'D000431933' 'D003512023' ... % FY0 dates, close
    'M' 'D000432078' 'aligndates(D001200056, D003512023-1)' ... % price. CIQ is daily
    'M' 'D000432082' 'D003500113' ... % BPS, value close
    'M' 'D000432098' 'D003500121' ... % DPS, perfect match
    'M' 'D000432130' 'D003500129' ... % EPS, perfect match, NORMALIZED
    'M' 'D000432131' 'D003500160' ... % EPS, perfect match, NORMALIZED
    'M' 'D000432194' 'D003500141' ... % SAL, perfect match
    'M' 'D000434624' 'D003505750' ... % FY1 BPS mean
    'M' 'D000434625' 'D003505751' ... % FY2 BPS mean
    'M' 'D000434644' 'D003509444' ... % ? FY1 BPS num down
    'M' 'D000434645' 'D003515229' ... % ? nothing found, FY2 BPS num down
    'M' 'D000434654' 'D003509439' ... % ? FY1 BPS num
    'M' 'D000434655' 'D003515224' ... % ? nothing found, FY2 BPS num
    'M' 'D000434664' 'D003509474' ... % ? FY1 BPS num up
    'M' 'D000434665' 'D003515259' ... % ? nothing found FY2 BPS num up
    'M' 'D000434784' 'D003505825' ... % FY1 CPS mean
    'M' 'D000434785' 'D003505826' ... % FY2 CPS mean
    'M' 'D000434804' 'D003509524' ... % ? FY1 CPS num down, short history
    'M' 'D000434805' 'D003515269' ... % ? nothing found FY2 CPS num down
    'M' 'D000434814' 'D003509519' ... % ? FY1 CPS num, short history from May 2008
    'M' 'D000434815' 'D003515264' ... % ? nothing found FY2 CPS num
    'M' 'D000434824' 'D003509554'...  % ? FY1 CPS num up, short history started from May 2008
    'M' 'D000434825' 'D003515299' ... % ? nothing found FY2 CPS num up
    'M' 'D000434944' 'D003505950' ... % FY1 DPS USD
    'M' 'D000434945' 'D003505951' ... % FY2 DPS USD
    'M' 'D000434964' 'D003509564' ... % ? 1Y DPS num down
    'M' 'D000434965' 'D003515309' ... % ? nothing found 2Y DPS num down
    'M' 'D000434974' 'D003509559' ... % ? 1Y DPS num
    'M' 'D000434975' 'D003515304' ... % ? nothing found, 2Y DPS num
    'M' 'D000434984' 'D003509594' ... % ? 1Y DPS up
    'M' 'D000434985' 'D003515339' ... % ? nothing found 2Y DPS up
    'M' 'D000435580' 'D003515975' ... % EPS, CUSTOMIZED
    'M' 'D000435584' 'D003515970' ... % EPS, CUSTOMIZED
    'M' 'D000435585' 'D003515971' ... % EPS, CUSTOMIZED
    'M' 'D000435586' 'D003515972' ... % EPS, CUSTOMIZED
    'M' 'D000435589' 'D003509418' ... % LT, IBES usd, CIQ reported
    'M' 'D000435594' 'D003506155' ... % EPS, NORMIZED, very close 
    'M' 'D000435595' 'D003506156' ... % EPS, very close 
    'M' 'D000435596' 'D003506157' ... % EPS, very close
    'M' 'D000435604' 'D003515998' ... % ? FY1 EPS DOWN, CUSTOMIZED
    'M' 'D000435605' 'D003516118' ... % ? FY2 EPS DOWN, CUSTOMIZED
    'M' 'D000435614' 'D003515993' ... % ? FY1 EPS num, CUSTOMIZED
    'M' 'D000435615' 'D003516113' ... % ? FY2 EPS num, CUSTOMIZED
    'M' 'D000435624' 'D003516023' ... % ? FY1 EPS UP, CUSTOMIZED
    'M' 'D000435625' 'D003516143' ... % ? FY2 EPS UP, CUSTOMIZED
    'M' 'D000435634' 'D003506135' ... % EPS, std, NORMALIZED
    'Y' 'D000436864' 'D003506475' ... % SAL
    'Y' 'D000437319' 'aligndates(leadts(D003500113,2),''A'')' ...  % BPS
    'Y' 'D000437351' 'aligndates(leadts(D003500121,2),''A'')' ...  % DPS
    'Y' 'D000437417' 'aligndates(leadts(D003500129,2),''A'')' ...  % EPS, NORMALIZED
    'Y' 'D000437545' 'aligndates(leadts(D003500141,2),''A'')' ...  % SAL, USD; Reported: D003500037
    'D' 'D000446805' @(D003505950) current(D003505950) ...   % USD; Reported: D003500776
    'D' 'D000448965' @(D003515970) current(D003515970) ...   % CUSTOMIZED, (D003506150 normalized), USD; Reported: D003500986
    'D' 'D000448966' @(D003515971) current(D003515971) ...   % CUSTOMIZED, (D003506151 normalized), USD; Reported: D003500987
    'D' 'D000448967' @(D003515972) current(D003515972) ...   % CUSTOMIZED, (D003506152 normalized), USD; Reported: D003501048
    'D' 'D000448970' @(D003509418) current(D003509418) ...   % value matched
    'D' 'D000449005' @(D003506155) current(D003506155) ...   % EPS, normalized, USD; Reported: D003501051
    'M' 'D000449135' @(D003506135) current(D003506135) ...   % EPS, normalized, standard deviation
    'D' 'D000453285' @(D003506475) current(D003506475) ...   % SAL, USD; Reported: D003501526
    'M' 'D000453774' 'D001200018 ./ 1e6'   ...   % aligned to monthly financial dates
    'D' 'D000453775' @(D001200009) current(D001200009) ...
    };


  diagIbes2CIQ = {...
    'M'	'D000411359'	'D003509418' ...
    'M'	'D000411369'	'D003509419' ...
    'M'	'D000411354'	'D003501046' ...
    'M'	'D000411364'	'D003501051' ...
    'M'	'D000411404'	'D003501031' ...
    'M'	'D000411355'	'D003501047' ...
    'M'	'D000411350'	'D003502540' ...
    'M'	'D000410178'	'D003500022' ...
    'M'	'D000453800'	'D003500160' ...
    'M'	'D000412479'	'' ...
    'M'	'D000412489'	'' ...
    'M'	'D000410559'	'' ...
    'M'	'D000410554'	'D003500626' ...
    'M'	'D000410555'	'D003500627' ...
    'M'	'D000410550'	'D003506694' ...
    'M'	'D000453791'	'D003500008' ...
    'M'	'D000453790'	'D003500008' ...
    'M'	'D000410719'	'' ...
    'M'	'D000410714'	'D003500776' ...
    'M'	'D000410724'	'D003500781' ...
    'M'	'D000410715'	'D003500777' ...
    'M'	'D000410710'	'D003500776' ...
    'M'	'D000453791'	'D003500073' ...
    'M'	'D000453792'	'D003500049' ...
    'M'	'D000412639'	'' ...
    'M'	'D000412634'	'D003501526' ...
    'M'	'D000412635'	'D003501527' ...
    'M'	'D000412630'	'D003501526' ...
    'M'	'D000453815'	'D003500037' ...
    'M'	'D000453816'	'D003500073' ...
    'M'	'D000410117'	'D003500249' ...
    'M'	'D000410125'	'D003500332' ...
    'M'	'D000410176'	'' ...
    'M'	'D000410178'	'D003500022' ...
    'M'	'D000415172'	'D003509438' ...
    'M'	'D000410234'	'D003500332' ...
    'M'	'D000453817'	'D003512023' ...
    'M'	'D000410146'	'D003500013' ...
    'M'	'D000453819'	'D003515944' ...
    'M'	'D000453776'	'D003512028' ...
    'M'	'D000453777'	'D003512029' ...
    'M'	'D000453778'	'D003512030' ...
    'M'	'D000453779'	'D003512031' ...
    'M'	'D000453780'	'D003512026' ...
    'M'	'D000453781'	'D003512027' ...
    'M'	'D000453782'	'' ...
    'M'	'D000453783'	'' ...
    'M'	'D000453784'	'' ...
    'M'	'D000453785'	'' ...
    'M'	'D000453817'	'D003512023' ...
    'M'	'D000453818'	'D003512023' ...
  }; %#ok<NASGU>
      
  m = ibes2CIQ; % worldScope2CIQ  diagIbes2CIQ];
  m = reshape(m, 3, numel(m)/3)';
end

function fts = current(fts)
   fts = fill(fts, inf, 'entry');
   fts = fts(end,:);
end

function x = growth(x,n)
     x = x ./ lagts(x,n);
     x = uniftsfun(x, @(v)nthroot(v,n)-1);
end

function tf = isItemCached(itemid)
% Remember we should not cache PIT items of 'D0020'
    tf = false;
    
%     o = DB('datacache');
%     ret = o.runSql(['select count(*) as num from api.itemmstr where id=''' itemid '''']);
%     if ret.num == 1
%         tf = true;
%     else
%         tf = false;
%         TRACE.Warn('%s not cached!\n', itemid);
%     end
end

