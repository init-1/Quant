classdef GE_Chg_DY_FY0 < GlobalEnhanced
    %GE_Chg_DY_FY0 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-400,'yyyy-mm-dd');
            factor = o.loadItem(secIds, 'D002420005', sDate, endDate);
            factor_12 = o.lagfts(factor, '12M');
            factorTS = o.diff_({factor_12 factor});
        end
    end
end
