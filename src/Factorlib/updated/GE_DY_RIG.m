classdef GE_DY_RIG < GlobalEnhanced
    %GE_DY_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            if o.isLive
                factorTS = o.loadItem(secIds, 'D000110101', startDate, endDate);
            else
                factorTS = o.loadItem(secIds, 'D000111346', startDate, endDate);
            end
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            factorTS = aligndates(factorTS, gics.dates);
            factorTS = o.RIG(factorTS, gics);
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
