classdef GE_DPS_GROWTH_5 < GlobalEnhanced
    %GE_DPS_GROWTH_5 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-6*370, 'yyyy-mm-dd'); % 5-y plus 1y lag possible
            DPS = o.loadItem(secIds, 'D000110146', sDate, endDate);
            DPS = backfill(DPS, o.DCF('15M'), 'entry');
            factorTS = o.estGrowth(DPS, o.DCF('12M'), o.DCF('6M'));
        end
    end
end
