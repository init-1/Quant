classdef GE_EARNING_GROWTH_FY1_3Y < GlobalEnhanced
    %GE_EARNING_GROWTH_FY1_3Y <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-3*370, 'yyyy-mm-dd');
            EPS_FY1 = o.loadItem(secIds, 'D000411364', sDate, endDate);
            factorTS = o.estGrowth({o.lagfts(EPS_FY1,'36M') o.lagfts(EPS_FY1,'24M') o.lagfts(EPS_FY1,'12M') EPS_FY1});
        end
    end
end
