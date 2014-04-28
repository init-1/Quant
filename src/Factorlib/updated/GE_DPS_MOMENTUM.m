classdef GE_DPS_MOMENTUM < GlobalEnhanced
    %GE_DPS_MOMENTUM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*720, 'yyyy-mm-dd');
            DPS = o.loadItem(secIds, 'D000110162', sDate, endDate);
            factorTS = o.momentum_TL({o.lagfts(DPS,'24M') o.lagfts(DPS,'12M') DPS});
        end
    end
end
