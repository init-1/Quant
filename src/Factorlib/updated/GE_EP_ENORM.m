classdef GE_EP_ENORM < GlobalEnhanced
    %GE_EP_ENORM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EPS_FY1 = o.loadItem(secIds, 'D000411364', startDate, endDate);
            EPS_FY2 = o.loadItem(secIds, 'D000411365', startDate, endDate);
            EPS_FY3 = o.loadItem(secIds, 'D000411366', startDate, endDate);
            LG = o.loadItem(secIds, 'D000411369', startDate, endDate);
            if o.isLive
                PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            
            BY = o.loadBondYield(secIds, startDate, endDate);
            
            [EPS_FY1,EPS_FY2,EPS_FY3,PR,LG] = aligndates(EPS_FY1,EPS_FY2,EPS_FY3,PR,LG,BY.dates);
            EY_FY1=EPS_FY1./PR;
            EY_FY2=EPS_FY2./PR;
            EY_FY3=EPS_FY3./PR;
            
            factorTS = o.eynorm(EY_FY1,EY_FY2,EY_FY3,LG/100,BY/100);
        end
    end
end
