classdef GE_INVENTORY_MOMENTUM < GlobalEnhanced
    %GE_INVENTORY_MOMENTUM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370, 'yyyy-mm-dd');
            INVTO = o.loadItem(secIds, 'D000110729', sDate, endDate);
            factorTS = o.diff_({o.lagfts(INVTO,'24M') o.lagfts(INVTO,'12M') INVTO});
        end
    end
end
