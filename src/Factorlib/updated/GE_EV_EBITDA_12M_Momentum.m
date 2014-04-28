classdef GE_EV_EBITDA_12M_Momentum < GlobalEnhanced
    %GE_EV_EBITDA_12M_Momentum <a full descriptive name placed here>
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
            EBITDA = o.loadItem(secIds, 'D000112408', sDate, endDate);
            EV = fill(EV, inf, 'entry');
            EBITDA = fill(EBITDA, inf, 'entry');
            factorTS = EBITDA ./ EV;
            factorTS = o.diff_({lagts(factorTS,13) lagts(factorTS,12) factorTS});
            factorTS = backfill(factorTS, int32(o.DCF('M')), 'entry');
        end
    end
end
