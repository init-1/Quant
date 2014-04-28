classdef GE_EARNING_GROWTH_1Y < GlobalEnhanced
    %GE_EARNING_GROWTH_1Y <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370, 'yyyy-mm-dd');
            EPS_FY1 = o.loadItem(secIds, 'D000411364', sDate, endDate);
            EPS_FY2 = o.loadItem(secIds, 'D000411365', sDate, endDate);
            EPS_FY3 = o.loadItem(secIds, 'D000411366', sDate, endDate);
            LG = o.loadItem(secIds, 'D000411369', sDate, endDate);
            PR_12 = o.loadItem(secIds, 'D000410126', sDate, endDate);
            if o.isLive
                PR = o.loadItem(secIds, 'D000453775', sDate, endDate);
            else
                PR = PR_12;
            end

            BY = o.loadBondYield(secIds, sDate, endDate);
            
            %%%[EPS_FY1,EPS_FY2,EPS_FY3,LG,PR,PR_12] = aligndates(EPS_FY1,EPS_FY2,EPS_FY3,LG,PR,PR_12,BY.dates);
            All = cellfun(@(x){backfill(x,o.DCF('3M'),'entry')}, {EPS_FY1,EPS_FY2,EPS_FY3,LG,BY,PR,PR_12});
            [EPS_FY1,EPS_FY2,EPS_FY3,LG,BY,PR,PR_12] = All{:};
            All = cellfun(@(x){o.lagfts(x,'12M')}, {EPS_FY1,EPS_FY2,EPS_FY3,LG,BY,PR_12});  % note that PR_12 lagged here
            [EPS_FY1_12,EPS_FY2_12,EPS_FY3_12,LG_12,BY_12,PR_12] = All{:};
            All = cellfun(@(x){o.lagfts(x,'24M')}, {EPS_FY1,EPS_FY2,EPS_FY3,LG,BY});  % note that PR_12 lagged here
            [EPS_FY1_24,EPS_FY2_24,EPS_FY3_24,LG_24,BY_24] = All{:};
            PR_24 = o.lagfts(PR_12, '12M');
            
            EY_FY1 = EPS_FY1./PR;
            EY_FY2 = EPS_FY2./PR;
            EY_FY3 = EPS_FY3./PR;
            EY_FY1_12 = EPS_FY1_12./PR_12;
            EY_FY2_12 = EPS_FY2_12./PR_12;
            EY_FY3_12 = EPS_FY3_12./PR_12;
            EY_FY1_24 = EPS_FY1_24./PR_24;
            EY_FY2_24 = EPS_FY2_24./PR_24;
            EY_FY3_24 = EPS_FY3_24./PR_24;
            
            EN = o.eynorm(EY_FY1,EY_FY2,EY_FY3,LG/100,BY/100) .* PR;
            EN_12 = o.eynorm(EY_FY1_12,EY_FY2_12,EY_FY3_12,LG_12/100,BY_12/100) .* PR_12;
            EN_24 = o.eynorm(EY_FY1_24,EY_FY2_24,EY_FY3_24,LG_24/100,BY_24/100) .* PR_24;
            factorTS = o.momentum_TL({EN_24 EN_12 EN});
        end
    end
end
