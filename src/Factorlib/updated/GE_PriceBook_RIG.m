classdef GE_PriceBook_RIG < GlobalEnhanced
    %GE_PriceBook_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            PB_A = o.loadItem(secIds, 'D000111021', startDate, endDate);
            PB_Q = o.loadItem(secIds, 'D000111345', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [PB_A,PB_Q] = aligndates(PB_A,PB_Q,gics.dates);
            factorTS = PB_Q;
            idx = isnan(fts2mat(factorTS));
            factorTS(idx) = PB_A(idx);
            factorTS = 1./factorTS;
            factorTS = o.RIG(factorTS, gics);
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
