function o = LoadUnivData(o, AggidOrSecid, startdate, enddate, isprod)            
        if nargin < 4
            isprod = 0;
        end

        if iscell(AggidOrSecid)
            secids = AggidOrSecid;
            dates = genDateSeries(startdate, enddate, 'D', 'BusDays', 0);
            tmpw = 1./numel(secids);
            o.bmhd = myfints(dates, repmat(tmpw, numel(dates), numel(secids)), secids);
        else
            aggid = AggidOrSecid;
            [secids, o.bmhd] = FactorAnalyzer.LoadIndexHolding(aggid, startdate, enddate, 0, o.freq, o.dateParam{:});
        end
        
        country = LoadSecInfo(secids,'country',startdate,enddate,0);
        country = country.country;
        include = ismember(country,o.ctrylist);
        if nansum(include) > 0
            secids(~include) = [];
            country(~include) = [];
            o.bmhd(:,~include) = [];
        end
        o.bmhd = bsxfun(@times,o.bmhd,1./cssum(o.bmhd));

        % get fwd return
        TRI = LoadRawItemTS(secids, 'D001410446', startdate, enddate);
        dailyret = Price2Return(TRI,1);             
        dates = genDateSeries(startdate, enddate, o.freq, o.dateParam{:});

        TRI_1Dlead = aligndates(leadts(TRI,1,nan), dates); % ignore the return on the first day after rebalancing - to be more practical
        totret = TRI_1Dlead./lagts(TRI_1Dlead,1,nan) - 1;

        o.fwdret = leadts(totret,1,NaN);
        o.fwdret(end,:) = [];

        % forward return by day
        o.fwdretByDay = cell(1,5);
        for i = 1:numel(o.fwdretByDay)
            o.fwdretByDay{i} = leadts(dailyret,i,NaN);
            o.fwdretByDay{i} = aligndates(o.fwdretByDay{i}, o.fwdret.dates);
        end

        % get different norm buckets
        o.gics = FactorAnalyzer.LoadSecTS(secids, '913', 0, startdate, enddate, o.freq, o.dateParam{:});            
        o.b2p = FactorAnalyzer.LoadFacDecile(secids, 'F00105', startdate, enddate, isprod, o.freq, o.nbucket, o.bmhd, o.dateParam{:});

        sectorcode = o.gics;
        sectorcode(:,:) = floor(fts2mat(2*1e-7*o.gics))-1;

        o.ctry = o.gics;   
        if isempty(o.ctrylist) || all(~strcmpi(o.ctrylist,''))
            o.ctrylist = unique(country)';
        end
        [~,loc] = ismember(country',o.ctrylist);
        o.ctry(:,:) = repmat(loc,size(o.ctry,1),1);            

        o.ctrysect = bsxfun(@plus,10*o.ctry,sectorcode);
        o.ctryb2p = bsxfun(@plus,10*o.ctry,o.b2p);

        o.mcap = FactorAnalyzer.LoadFacDecile(secids, 'F00072', startdate, enddate, isprod, o.freq, o.nbucket, o.bmhd, o.dateParam{:});
        o.beta = FactorAnalyzer.LoadItemDecile(secids, 'D001500002', startdate, enddate, o.freq, o.nbucket, o.bmhd, o.dateParam{:});
        o.brcost = FactorAnalyzer.LoadItemDecile(secids, 'D003010066', startdate, enddate, o.freq, o.nbucket, o.bmhd, o.dateParam{:});
        o.brcost = -o.brcost + o.nbucket + 1;
        
        % calcualte the adv
        price = LoadRawItemTS(secids, 'D001410415', startdate, enddate);
        volume = LoadRawItemTS(secids, 'D001410431', startdate, enddate);
        [price, volume] = aligndata(price, volume);
        o.adv = ftsmovavg(price*volume,21,1); % 21 days average dollar volume
        interval = 100/o.nbucket;
        o.adv = csRankPrc(o.adv, 'ascend');
        o.adv(:,:) = ceil(fts2mat(o.adv)./interval);
        
        % align data                
        [o.fwdretByDay{:}, o.fwdret, o.bmhd, o.gics, o.ctry, o.ctrysect, o.ctryb2p, o.mcap, o.beta, o.b2p,o.brcost,o.adv] = ...
            aligndata(o.fwdretByDay{:}, o.fwdret, o.bmhd, o.gics, o.ctry, o.ctrysect, o.ctryb2p, o.mcap, o.beta, o.b2p,o.brcost,o.adv,o.fwdret.dates);
        
end