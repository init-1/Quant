classdef GE_CF_P < GlobalEnhanced
    %GE_CF_P <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            CPS_Q = o.loadItem(secIds, 'D000111623', startDate, endDate);
            CPS_A = o.loadItem(secIds, 'D000110142', startDate, endDate);
            if o.isLive
                PR = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
            CPS = CPS_Q;
            index= isnan(fts2mat(CPS));
            CPS(index) = CPS_A(index);
            factorTS = backfill(CPS ./ PR, o.DCF('2M'), 'entry');
        end
    end
end
