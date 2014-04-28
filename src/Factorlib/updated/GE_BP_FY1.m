classdef GE_BP_FY1 < GlobalEnhanced
    %GE_BP_FY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            BPS_FY1 = o.loadItem(secIds, 'D000410404', startDate, endDate);
            if o.isLive
                PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            factorTS = BPS_FY1 ./ PR;
        end
    end
end
