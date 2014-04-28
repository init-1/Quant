classdef GE_DebtEquity_RIG < GlobalEnhanced
    %GE_DebtEquity_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            DE_A = o.loadItem(secIds, 'D000111205', startDate, endDate);
            DE_Q = o.loadItem(secIds, 'D000111726', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [DE_A,DE_Q] = aligndates(DE_A,DE_Q,gics.dates);
            factorTS = DE_Q;
            idx = isnan(fts2mat(factorTS));
            factorTS(idx) = DE_A(idx);
            factorTS = o.RIG(factorTS,gics);
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
