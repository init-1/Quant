classdef GE_EV_EBIT_12M_Momentum_RIG < GlobalEnhanced
    %GE_EV_EBIT_12M_Momentum_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-17*31, 'yyyy-mm-dd');
            EV = o.loadItem(secIds, 'D000110514', sDate, endDate);
            EBIT = o.loadItem(secIds, 'D000110473', sDate, endDate);
            EV = fill(EV, inf, 'entry');
            EBIT = fill(EBIT, inf, 'entry');
            factorTS = EBIT ./ EV;
            factorTS = o.diff_({o.lagfts(factorTS,'13M') o.lagfts(factorTS,'12M') factorTS});
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            factorTS = aligndates(factorTS, gics.dates);
            factorTS = o.RIG(factorTS, gics);
            factorTS = backfill(factorTS, o.DCF('M'), 'entry');
        end
    end
end
