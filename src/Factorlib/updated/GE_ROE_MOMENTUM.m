classdef GE_ROE_MOMENTUM < GlobalEnhanced
    %GE_ROE_MOMENTUM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370, 'yyyy-mm-dd');
            ROE = o.loadItem(secIds, 'D000111154', sDate, endDate);
            factorTS = o.diff_({o.lagfts(ROE,'24M') o.lagfts(ROE,'12M') ROE});
        end
    end
end
