classdef GB_Mom_EPSFY1 < GlobalEnhanced
    %GB_Mom_EPSFY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate, mon)
            sDate = datestr(datenum(startDate)-15*31-round(o.DCF(mon,'D')*1.5), 'yyyy-mm-dd');
            FY0 = o.loadItem(secIds, 'D000431933', sDate, endDate);
            FY1 = o.loadItem(secIds, 'D000415183', sDate, endDate);
            FY2 = o.loadItem(secIds, 'D000415184', sDate, endDate);
            EPS_FY1_MD = o.loadItem(secIds, 'D000411364', sDate, endDate);
            EPS_FY2_MD = o.loadItem(secIds, 'D000411365', sDate, endDate);
            EPS_FY0_RV = o.loadItem(secIds, 'D000410178', sDate, endDate);
            
            if o.isLive
                EPS_FY0_PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                EPS_FY0_PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            EPS_FY0_PR = fill(EPS_FY0_PR, Inf, 'entry');
            
            momentum = o.IBES_momentum(FY0, FY1, FY2, EPS_FY0_RV, EPS_FY1_MD, EPS_FY2_MD, o.DCF(mon));
            momentum = aligndates(momentum, EPS_FY0_PR.dates);
            momentum(EPS_FY0_PR <= 0) = NaN;
            factorTS = momentum ./ EPS_FY0_PR;
        end
    end
end
