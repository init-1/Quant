classdef GE_ROE_BPSEPS < GlobalEnhanced
    %GE_ROE_BPSEPS <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            BPS = o.loadItem(secIds, 'D000410404', startDate, endDate);
            EPS = o.loadItem(secIds, 'D000411364', startDate, endDate);
            factorTS = EPS ./ BPS;
            factorTS(BPS == 0) = 18.7;
        end
    end
end
