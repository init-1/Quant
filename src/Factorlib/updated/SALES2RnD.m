classdef SALES2RnD < FacBase
    %SALES2RnD <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sdate_b = datestr(addtodate(datenum(startDate),-24,'M'),'yyyy-mm-dd');
            RnD = o.loadItem(secIds,'D000686681',sdate_b,endDate,4);
            sales = o.loadItem(secIds,'D000686629',sdate_b,endDate,4);
            sales = ftsnanmean(sales{:})*4;
            RnD = ftsnanmean(RnD{:})*4;
            [sales, RnD] = aligndata(sales, RnD);
            factorTS = sales./RnD;
            factorTS(factorTS == 0) = nan;
        end
    end
end
%Factory.RunRegistered('F00237','0064659372',2,0,'2003-12-31','2011-12-31')
