classdef GE_FORWARD_E_GROWTH < GlobalEnhanced
    %GE_FORWARD_E_GROWTH <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EPS_FY0 = o.loadItem(secIds, 'D000410178', startDate, endDate);
            EPS_FY1 = o.loadItem(secIds, 'D000411364', startDate, endDate);
            EPS_FY2 = o.loadItem(secIds, 'D000411365', startDate, endDate);
            EPS_FY3 = o.loadItem(secIds, 'D000411366', startDate, endDate);
            factorTS = o.estGrowth({EPS_FY0,EPS_FY1,EPS_FY2,EPS_FY3});
        end
    end
end
