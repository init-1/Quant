classdef ACCURVOL < FacBase
    %ACCURVOL <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-48*30,'yyyy-mm-dd');
            assetItem = 'D000111193';
            assets = o.loadItem(secIds, assetItem, sDate, endDate);
            assets = backfill(assets, o.DCF('18M'), 'entry');
            
            tot_cur_asset_ = o.loadItem(secIds,'D000686131',sDate,endDate,1);
            tot_cur_liability_ = o.loadItem(secIds,'D000686132',sDate,endDate,1);
            cash_st_inv_ = o.loadItem(secIds,'D000679586',sDate,endDate,1);
            debt_st_ = o.loadItem(secIds,'D000686584',sDate,endDate,1);
            %assetItem = 'D000679525';
            %optaccrual = o.loadItem(secIds,assetItem,sDate, endDate,1);
            assetItem = 'D000679525';
            depreamort = o.loadItem(secIds,assetItem,sDate, endDate,1);
            
            assetItem = 'D000686629';
            sales = o.loadItem(secIds,assetItem,sDate, endDate,1);
            
            depreamort = backfill(depreamort{1},o.DCF('18M'),'entry');
            sales = backfill(sales{1},o.DCF('18M'),'entry');
            assets = backfill(assets,o.DCF('18M'),'entry');
            tot_cur_asset = backfill(tot_cur_asset_{1},o.DCF('18M'),'entry');
            tot_cur_liability = backfill(tot_cur_liability_{1},o.DCF('18M'),'entry');
            cash_st_inv = backfill(cash_st_inv_{1},o.DCF('18M'),'entry');
            debt_st = backfill(debt_st_{1},o.DCF('18M'),'entry');
            
            [depreamort,sales,assets,tot_cur_asset,tot_cur_liability,cash_st_inv,debt_st] = aligndata(depreamort,sales,assets,tot_cur_asset,tot_cur_liability,cash_st_inv,debt_st);
            
            depreamort(isnan(depreamort)) = 0;
            tot_cur_asset(isnan(tot_cur_asset)) = 0;
            tot_cur_liability(isnan(tot_cur_liability)) = 0;
            cash_st_inv(isnan(cash_st_inv)) = 0;
            debt_st(isnan(debt_st)) = 0;
            
            optaccrual = (tot_cur_asset - cash_st_inv) - (tot_cur_liability - debt_st);
            optaccrual_adj1 = bsxfun(@rdivide,(optaccrual - depreamort),sales);
            optaccrual_adj2 = bsxfun(@rdivide,(optaccrual - depreamort),assets*1000000);
            
            optaccrual_adj1_4q = o.lagfts(optaccrual_adj1, '12M',  NaN);
            optaccrual_adj2_4q = o.lagfts(optaccrual_adj2, '12M',  NaN);
            optaccrual_adj1_mat = fts2mat(optaccrual_adj1);
            optaccrual_adj2_mat = fts2mat(optaccrual_adj2);
            optaccrual_adj1_4q_mat = fts2mat(optaccrual_adj1_4q);
            optaccrual_adj2_4q_mat = fts2mat(optaccrual_adj2_4q);
            betaPeriod = 48;
            accvol = nan(size(optaccrual_adj1_mat,1),numel(secIds));
            for i = 1:numel(secIds)
                for j = betaPeriod+1 : size(optaccrual_adj1_mat,1)
                    sec = optaccrual_adj1_4q_mat(j-betaPeriod:j-1,i);
                    y = optaccrual_adj1_mat(j-betaPeriod:j-1,i);
                    sec_ = sec;
                    nanNum = sum(isnan(sec_));
                    sec(isnan(sec_)) = [];
                    y(isnan(sec_)) = [];
                    if nanNum < 0.5*betaPeriod
                        [b,bint,r] = regress(y,[ones(length(y),1) sec]);
                        accvol(j,i) = nanstd(r);
                    end
                end
            end
            
            factorTS = myfints(optaccrual_adj1.dates, accvol, fieldnames(optaccrual_adj1,1));
            factorTS = fill(factorTS, Inf, 'entry');
        end
    end
end
