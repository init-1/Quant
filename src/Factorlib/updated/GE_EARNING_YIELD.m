classdef GE_EARNING_YIELD < GlobalEnhanced
    %GE_EARNING_YIELD <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EPS_Q = o.loadItem(secIds, 'D000111622', startDate, endDate);
            EPS_A = o.loadItem(secIds, 'D000110193', startDate, endDate);
            
            if o.isLive
                PR = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
            
            EPS = EPS_Q;
            index = isnan(fts2mat(EPS));
            EPS(index) = EPS_A(index);
            factorTS = backfill(EPS ./ PR, o.DCF('2M'), 'entry');
        end
    end
end
