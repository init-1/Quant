classdef GE_NetMargin_RIG < GlobalEnhanced
    %GE_NetMargin_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            NM_A = o.loadItem(secIds, 'D000110842', startDate, endDate);
            NM_Q = o.loadItem(secIds, 'D000111339', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [NM_A, NM_Q] = aligndates(NM_A, NM_Q, gics.dates);
            
            factorTS = NM_Q;
            idx = isnan(fts2mat(factorTS));
            factorTS(idx) = NM_A(idx);
            factorTS = o.RIG(factorTS, gics);
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
