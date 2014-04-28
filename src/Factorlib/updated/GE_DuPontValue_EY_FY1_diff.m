classdef GE_DuPontValue_EY_FY1_diff < GlobalEnhanced
    %GE_DuPontValue_EY_FY1_diff <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, sids, startDate, endDate)
            secIds = LoadIndexHoldingTS('0064891800', startDate, endDate, 0, o.freq);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            gics = fill(gics,inf,'entry');
            
            FY1 = o.loadItem(secIds, 'D000415183', startDate, endDate);
            FY2 = o.loadItem(secIds, 'D000415184', startDate, endDate);
            FY3 = o.loadItem(secIds, 'D000415185', startDate, endDate);
            
            %get the forward 12 month sales
            SAL_F1_MD = o.loadItem(secIds, 'D000412644', startDate, endDate);
            SAL_F2_MD = o.loadItem(secIds, 'D000412645', startDate, endDate);
            SAL_F3_MD = o.loadItem(secIds, 'D000412646', startDate, endDate);
            SALES_FWD12 = 1e6 .* o.IBES_FWD12(FY1, FY2, FY3, SAL_F1_MD, SAL_F2_MD, SAL_F3_MD);
            
            %get the forward 12 month earnings
            EPS_F1_MD = o.loadItem(secIds, 'D000411364', startDate, endDate);
            EPS_F2_MD = o.loadItem(secIds, 'D000411365', startDate, endDate);
            EPS_F3_MD = o.loadItem(secIds, 'D000411366', startDate, endDate);
            EPS_FWD12 = o.IBES_FWD12(FY1, FY2, FY3, EPS_F1_MD, EPS_F2_MD, EPS_F3_MD);
            
            %get the total assets
            Assets_A = o.loadItem(secIds, 'D000111193', startDate, endDate);
            Assets_Q = o.loadItem(secIds, 'D000111412', startDate, endDate);
            
            TOT_ASSETS = Assets_Q;
            idx = isnan(TOT_ASSETS);
            TOT_ASSETS(idx) = Assets_A(idx);
            
            %debt to equity ratio
            DE_A = o.loadItem(secIds, 'D000111205', startDate, endDate);
            DE_Q = o.loadItem(secIds, 'D000111726', startDate, endDate);
            
            LEVERAGE = DE_Q;
            idx = isnan(LEVERAGE);
            LEVERAGE(idx) = DE_A(idx);
            
            %forward bvps
            BPS_FWD12 = o.loadItem(secIds, 'D000410404', startDate, endDate);
            
            %Price & Shares data
            if o.isLive
                PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            
            nShares = o.loadItem(secIds, 'D000110115', startDate, endDate);
            
            %align data
                      [SALES_FWD12,EPS_FWD12,TOT_ASSETS,LEVERAGE,BPS_FWD12,PR,nShares] = ...
            aligndates(SALES_FWD12,EPS_FWD12,TOT_ASSETS,LEVERAGE,BPS_FWD12,PR,nShares,gics.dates);
            
            %Calculate DuPont items
            ftscell{1} = nShares.*EPS_FWD12./(SALES_FWD12);      %forecast profit margin
            ftscell{2} = SALES_FWD12./TOT_ASSETS;                %Asset turnover
            ftscell{3} = LEVERAGE;                               %Geraing
            ftscell{4} = BPS_FWD12./PR;                          %Forward Book to Price
            ftscell{5} = EPS_FWD12./PR;                          %Foraward PE
            
            %let's do the real business
            pediff = o.calculation(ftscell,gics);
            factorTS = padfield(pediff, sids);
        end
    end
    
    methods(Access = protected, Static)
        function newfts = calculation(ftscell,gics)
            super_sector_gics = {[10,151040],[40,4040],[4040,55,203050],[35,30,45,50],[20,203050,25,15,151040]};
            super_sector_include = {[1,1],[1,0],[1,1,1],[1,1,1,1],[1,0,1,1,0]};
            Ngroup = numel(super_sector_gics);
            gicsmat = fts2mat(gics);
            newfts = ftscell{end};
            newfts(:,:) = nan;
            onefts = newfts;
            onefts(:,:) = 1;
            
            for i=1:Ngroup
                code_list = super_sector_gics{i};
                include_idx = super_sector_include{i};
                picked = gics;
                picked(:,:) = 0;
                for j = 1:length(code_list)
                    [~,level] = size(num2str(code_list(j)));
                    g = floor(gicsmat./10^(8-level));
                    picked(g==code_list(j)) = include_idx(j);
                end
                
                regdata = ftscell;
                for j = 1:numel(ftscell)
                    ofts = ftscell{j};
                    ofts(picked==0) = nan;
                    ofts(ofts < 0) = nan;
                    ofts = uniftsfun(ofts,@log);
                    ofts(isinf(ofts)) = nan;
                    regdata{j} = ofts;
                end
                
                %do the magic
                yfts = regdata{end};
                [~,resfts,~,~,~] = csregress(yfts,{onefts regdata{1:end-1}});
                modelPE = uniftsfun(bsxfun(@plus,yfts,-resfts),@exp);
                fwdPE = ftscell{end};
                r = (fwdPE - modelPE)./modelPE;
                newfts(picked==1) = r(picked==1);
            end
        end
    end
end
