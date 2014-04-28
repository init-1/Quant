classdef GE_EV_EBITDA_12M_PIT < GlobalEnhanced
    %GE_EV_EBITDA_12M_PIT <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EBITDA_Itemid ='D000679559'; % PIT itemid
            ltdebtItemid = 'D000679633'; %PIT itemid
            cashItemid = 'D000679586'; %PIT itemid
            prcItemid = 'D001410415';
            sharesItemid = 'D001410472';
            numQtrs = 4;
            
            % sDate - to have 1 year extra data for avg/sum over 4 qtrs calc
            sDate = datestr(addtodate(datenum(startDate),-18,'M'),'yyyy-mm-dd');
            
            % PIT items
            ebitda = o.loadItem(secIds,EBITDA_Itemid,sDate,endDate,numQtrs);
            debt_lt = o.loadItem(secIds,ltdebtItemid,sDate,endDate,numQtrs);
            cash = o.loadItem(secIds,cashItemid,sDate,endDate,numQtrs);
            
            % TS items
            closeprice = o.loadItem(secIds,prcItemid,sDate,endDate);
            shares = o.loadItem(secIds,sharesItemid,sDate,endDate);
            
            % calculate the avg of debt_lt and cash items over n qtr period
            cash_avg = ftsnanmean(cash{:});
            debt_lt_avg = ftsnanmean(debt_lt{:});
            ebitda_avg = ftsnanmean(ebitda{:});
            
            % calculate the mkt cap
            mkt_cap = closeprice * shares;
            
            % backfill the cash, debt_lt, sales, mkt_cap data
            nbf = o.DCF('3M');
            cash_avg = backfill(cash_avg,nbf,'entry');
            debt_lt_avg = backfill(debt_lt_avg,nbf,'entry');
            ebitda_avg = backfill(ebitda_avg,nbf,'entry');
            mkt_cap = backfill(mkt_cap,nbf,'entry');
            
            %% Step 3: calculate factor value
            % divide mkt cap by 1 million and add long tem debt subtract cash and divide the whole by sales
            ev = ftsnansum(mkt_cap/1000000, debt_lt_avg, -cash_avg);
            ebitdaev = ebitda_avg / ev;
            factorTS = o.diff_({o.lagfts(ebitdaev,'13M'),o.lagfts(ebitdaev,'12M'), ebitdaev});
        end
    end
end
