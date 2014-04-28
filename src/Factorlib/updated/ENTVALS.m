classdef ENTVALS < FacBase
    %ENTVALS <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
        %% Parameters
            salesItemid = 'D000686629'; %PIT itemid
            ltdebtItemid = 'D000679633'; %PIT itemid
            cashItemid = 'D000679586'; %PIT itemid
            prcItemid = 'D001410415';
            sharesItemid = 'D001410472';
        
            numQtrs = 4;

            % sDate - to have 1 year extra data for avg/sum over 4 qtrs calc
            sDate_debt = datestr(addtodate(datenum(startDate),-12,'M'),'yyyy-mm-dd');
            
            % PIT items
            sales = o.loadItem(secIds,salesItemid,sDate_debt,endDate,numQtrs);
            debt_lt = o.loadItem(secIds,ltdebtItemid,sDate_debt,endDate,numQtrs);
            cash = o.loadItem(secIds,cashItemid,sDate_debt,endDate,numQtrs);
            
            % TS items
            sDate_pr = datestr(addtodate(datenum(startDate),-31,'D'),'yyyy-mm-dd');
            closeprice = o.loadItem(secIds,prcItemid,sDate_pr,endDate);
            shares = o.loadItem(secIds,sharesItemid,sDate_pr,endDate);
            
            % calculate the avg of debt_lt and cash items over n qtr period
            cash_avg = ftsnanmean(cash{:});
            debt_lt_avg = ftsnanmean(debt_lt{:});
            
            % calculate the sum of sales item over n qtr period
            sales_sum = ftsnanmean(sales{:})*4;
            
            % Genereate the date series
            Dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            
            % match the items
            [cash_avg, debt_lt_avg, sales_sum, closeprice, shares] = aligndata(cash_avg, debt_lt_avg, sales_sum, closeprice, shares, Dates);
            
            % calculate the mkt cap
            mkt_cap = closeprice.*shares;
            
            % backfill the cash, debt_lt, sales, mkt_cap data
            nbf = o.DCF('3M');
            cash_avg = backfill(cash_avg,nbf,'entry');
            debt_lt_avg = backfill(debt_lt_avg,nbf,'entry');
            sales_sum = backfill(sales_sum,nbf,'entry');
            mkt_cap = backfill(mkt_cap,nbf,'entry');
            
            % divide mkt cap by 1 million and add long tem debt subtract cash and divide the whole by sales
            factorTS = ftsnansum(mkt_cap/1000000, debt_lt_avg, -cash_avg)./sales_sum;
        end
    end
end
