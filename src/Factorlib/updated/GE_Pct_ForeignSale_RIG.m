classdef GE_Pct_ForeignSale_RIG < GlobalEnhanced
    %GE_Pct_ForeignSale_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            FS = o.loadItem(secIds, 'D000110578', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            FS = aligndates(FS, gics.dates);
            factorTS = o.RIG(FS, gics);
            factorTS = backfill(factorTS, o.DCF('12M'), 'entry');
        end
    end
end
