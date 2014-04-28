classdef GE_NETMARGIN_MOMENTUM < GlobalEnhanced
    %GE_NETMARGIN_MOMENTUM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370, 'yyyy-mm-dd');
            NM = o.loadItem(secIds, 'D000111339', sDate, endDate);
            NM = backfill(NM, o.DCF('6M'), 'entry');
            factorTS = o.diff_({lagts(NM,24) lagts(NM,12) NM});
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
