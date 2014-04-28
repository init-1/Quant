classdef GE_EARNING_GROWTH_FY2 < GlobalEnhanced
    %GE_EARNING_GROWTH_FY2 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370,'yyyy-mm-dd');
            EPS_FY2 = o.loadItem(secIds, 'D000411365', sDate, endDate);
            EPS_FY0 = o.loadItem(secIds, 'D000410178', sDate, endDate);
            EDIFF = EPS_FY2-EPS_FY0;
            EDIFF_12 = o.lagfts(EDIFF, '12M');
            EDIFF_24 = o.lagfts(EDIFF, '24M');
            
            factorTS = o.momentum_TL({EDIFF_24, EDIFF_12, EDIFF});
        end
    end
end
