classdef GE_NETMARGIN < GlobalEnhanced
    %GE_NETMARGIN <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            NM_Q = o.loadItem(secIds, 'D000111339', startDate, endDate);
            NM_A = o.loadItem(secIds, 'D000110842', startDate, endDate);
            NM = NM_Q;
            index = isnan(fts2mat(NM));
            NM(index) = NM_A(index);
            factorTS = backfill(NM, o.DCF('2M'), 'entry');
        end
    end
end
