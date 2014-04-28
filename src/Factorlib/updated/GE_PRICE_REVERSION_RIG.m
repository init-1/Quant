classdef GE_PRICE_REVERSION_RIG < GE_PRICE_REVERSION
    %GE_PRICE_REVERSION_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('D');
            sDate = datestr(datenum(startDate)-60,'yyyy-mm-dd');
            factorTS = o.loadItem(secIds, 'D000310017', sDate, endDate);
            factorTS = backfill(factorTS, o.DCF('5D'), 'entry');
            factorTS = o.VF(factorTS, 15, 30); %%% probably an error in original
            gics = LoadQSSecTS(secIds, 913, 0, sDate, endDate, o.freq);
            factorTS = aligndates(factorTS, gics.dates);
            factorTS = o.RIG(factorTS, gics);
        end
    end
end
