classdef EBITDAPEV < FacBase
    %EBITDAPEV <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EBITDA_Itemid ='D000679559'; % PIT itemid
            ltdebtItemid = 'D000679633'; %PIT itemid
            cashItemid = 'D000679586'; %PIT itemid
            prcItemid = 'D001410415';
            sharesItemid = 'D001410472';
        
            numQtrs = 4;
        
            sDate_debt = datestr(addtodate(datenum(startDate),-12,'M'),'yyyy-mm-dd');

            % PIT items
            ebitda = o.loadItem(secIds,EBITDA_Itemid,sDate_debt,endDate,numQtrs);
            debt_lt = o.loadItem(secIds,ltdebtItemid,sDate_debt,endDate,numQtrs);
            cash = o.loadItem(secIds,cashItemid,sDate_debt,endDate,numQtrs);
            
            % TS items
            sDate_pr = datestr(addtodate(datenum(startDate),-31,'D'),'yyyy-mm-dd');
            closeprice = o.loadItem(secIds,prcItemid,sDate_pr,endDate);
            shares = o.loadItem(secIds,sharesItemid,sDate_pr,endDate);
            
            % calculate the avg of debt_lt and cash items over n qtr period
            cash_avg = ftsnanmean(cash{:});
            debt_lt_avg = ftsnanmean(debt_lt{:});
            ebitda_avg = ftsnanmean(ebitda{:});
               
            % Genereate the date series, month end dates
            Dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            
            % match the items
            [cash_avg, debt_lt_avg, ebitda_avg, closeprice, shares] = aligndata(cash_avg, debt_lt_avg, ebitda_avg, closeprice, shares, Dates);
            %[cash_avg, debt_lt_avg, ebitda_avg, closeprice, shares] = aligndata(cash_avg, debt_lt_avg, ebitda_avg, closeprice, shares, Dates,'union');
            % calculate the mkt cap
            mkt_cap = closeprice * shares;
            
            % backfill the cash, debt_lt, sales, mkt_cap data
            nbf = o.DCF('3M');
            cash_avg = backfill(cash_avg,nbf,'entry');
            debt_lt_avg = backfill(debt_lt_avg,nbf,'entry');
            ebitda_avg = backfill(ebitda_avg,nbf,'entry');
            mkt_cap = backfill(mkt_cap,nbf,'entry');
            
            % divide mkt cap by 1 million and add long tem debt subtract cash and divide the whole by sales
            ev = ftsnansum(mkt_cap/1000000, debt_lt_avg, -cash_avg);
            factorTS = ebitda_avg / ev;
        end
    end
end
