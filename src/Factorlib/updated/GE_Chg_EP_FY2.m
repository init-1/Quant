classdef GE_Chg_EP_FY2 < GlobalEnhanced
    %GE_Chg_EP_FY2 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-450, 'yyyy-mm-dd');
            factor = o.loadItem(secIds, 'D002420012', sDate, endDate);
            factor = backfill(factor, o.DCF('18M'), 'entry');
            factor_12 = o.lagfts(factor, '12M');
            factorTS = o.diff_({factor_12 factor});
        end
    end
end
