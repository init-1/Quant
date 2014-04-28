classdef GE_Mom_3M_TRAIL_EPS < GlobalEnhanced
    %GE_Mom_3M_TRAIL_EPS <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-5*31, 'yyyy-mm-dd');
            FY0 = o.loadItem(secIds, 'D000431933', sDate, endDate);
            %%%%FY1 = o.loadItem(secIds, 'D000415183', sDate, endDate);
            EPS_FY1_MD = o.loadItem(secIds, 'D000411364', sDate, endDate);
            EPS_FY0_RV = o.loadItem(secIds, 'D000410178', sDate, endDate);
            
            TRAIL12 = o.IBES_TRAIL12(FY0, EPS_FY0_RV, EPS_FY1_MD);
            factorTS = o.momentum_TL({o.lagfts(TRAIL12,'3M') TRAIL12});
        end
    end
end
