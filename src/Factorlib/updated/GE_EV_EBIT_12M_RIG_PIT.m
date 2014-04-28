classdef GE_EV_EBIT_12M_RIG_PIT < GlobalEnhanced
    %GE_EV_EBIT_12M_RIG_PIT <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            ebit_Itemid ='D000679558'; % PIT itemid
            ltdebtItemid = 'D000679633'; %PIT itemid
            cashItemid = 'D000679586'; %PIT itemid
            prcItemid = 'D001410415';
            sharesItemid = 'D001410472';
            numQtrs = 4;
        
            % sDate - to have 1 year extra data for avg/sum over 4 qtrs calc
            sDate = datestr(addtodate(datenum(startDate),-18,'M'),'yyyy-mm-dd');
            
            % PIT items
            ebit = o.loadItem(secIds,ebit_Itemid,sDate,endDate,numQtrs);
            debt_lt = o.loadItem(secIds,ltdebtItemid,sDate,endDate,numQtrs);
            cash = o.loadItem(secIds,cashItemid,sDate,endDate,numQtrs);
            
            % TS items
            closeprice = o.loadItem(secIds,prcItemid,sDate,endDate);
            shares = o.loadItem(secIds,sharesItemid,sDate,endDate);
            gics = LoadQSSecTS(secIds, 913, 0, sDate, endDate, o.freq);
            
            % calculate the avg of debt_lt and cash items over n qtr period
            cash_avg = ftsnanmean(cash{:});
            debt_lt_avg = ftsnanmean(debt_lt{:});
            ebit_avg = ftsnanmean(ebit{:});
            
            % calculate the mkt cap
            mkt_cap = closeprice * shares;
            
            % backfill the cash, debt_lt, sales, mkt_cap data
            nbf = o.DCF('3M');
            cash_avg = backfill(cash_avg,nbf,'entry');
            debt_lt_avg = backfill(debt_lt_avg,nbf,'entry');
            ebit_avg = backfill(ebit_avg,nbf,'entry');
            mkt_cap = backfill(mkt_cap,nbf,'entry');
            
            % divide mkt cap by 1 million and add long tem debt subtract cash and divide the whole by sales
            ev= ftsnansum(mkt_cap/1000000, debt_lt_avg, -cash_avg);
            ebitev = ebit_avg / ev;
            factorTS = o.diff_({o.lagfts(ebitev,'13M'), o.lagfts(ebitev,'12M'), ebitev});
            factorTS = aligndates(factorTS, gics.dates);
            factorTS = o.RIG(factorTS, gics);
        end
    end
end
