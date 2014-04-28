classdef GE_Div_Payout_RIG < GlobalEnhanced
    %GE_Div_Payout_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            PayOut = o.loadItem(secIds, 'D000110440', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            PayOut = aligndates(PayOut, gics.dates);
            factorTS = o.RIG(PayOut, gics);
            factorTS = backfill(factorTS, o.DCF('12M'), 'entry');
        end
    end
end
