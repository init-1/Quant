classdef GE_EY_FY1 < GlobalEnhanced
    %GE_EY_FY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EPS_FY1 = o.loadItem(secIds, 'D000411364', startDate, endDate);
            if o.isLive
                PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            factorTS = EPS_FY1 ./ PR;
        end
    end
end
