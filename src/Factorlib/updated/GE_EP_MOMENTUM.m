classdef GE_EP_MOMENTUM < GlobalEnhanced
    %GE_EP_MOMENTUM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-370,'yyyy-mm-dd');
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
            
            [EPS_FY1,EPS_FY2,EPS_FY3,LG,PR,PR_12] = aligndates(EPS_FY1,EPS_FY2,EPS_FY3,LG,PR,PR_12,BY.dates);
            All = cellfun(@(x){backfill(x,o.DCF('3M'),'entry')}, {EPS_FY1,EPS_FY2,EPS_FY3,LG,BY,PR,PR_12});
            [EPS_FY1,EPS_FY2,EPS_FY3,LG,BY,PR,PR_12] = All{:};
            All = cellfun(@(x){o.lagfts(x,'12M')}, {EPS_FY1,EPS_FY2,EPS_FY3,LG,BY,PR_12});  % note that PR_12 lagged here
            [EPS_FY1_12,EPS_FY2_12,EPS_FY3_12,LG_12,BY_12,PR_12] = All{:};
            EY_FY1 = EPS_FY1./PR;
            EY_FY2 = EPS_FY2./PR;
            EY_FY3 = EPS_FY3./PR;
            EY_FY1_12 = EPS_FY1_12./PR_12;
            EY_FY2_12 = EPS_FY2_12./PR_12;
            EY_FY3_12 = EPS_FY3_12./PR_12;
            
            EN = o.eynorm(EY_FY1,EY_FY2,EY_FY3,LG/100,BY/100);
            EN_12 = o.eynorm(EY_FY1_12,EY_FY2_12,EY_FY3_12,LG_12/100,BY_12/100);
            factorTS = o.diff_({EN_12 EN});
        end
    end
end
