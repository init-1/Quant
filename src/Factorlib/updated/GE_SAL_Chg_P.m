classdef GE_SAL_Chg_P < GlobalEnhanced
    %GE_SAL_Chg_P <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sdate = datestr(datenum(startDate)-2*31, 'yyyy-mm-dd');
            SALESP_FY1 = o.loadItem(secIds, 'D002420037', sdate, endDate);
            SALESP_FY2 = o.loadItem(secIds, 'D002420038', sdate, endDate);
            factorTS = SALESP_FY2 - SALESP_FY1;
        end
    end
end
