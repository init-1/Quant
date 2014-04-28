classdef GE_TR_MOMENTUM < GlobalEnhanced
    %GE_TR_MOMENTUM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-200, 'yyyy-mm-dd');
            RI = o.loadItem(secIds, 'D000310006', sDate, endDate);
            factorTS = o.momentum_TL({o.lagfts(RI,'6M') o.lagfts(RI,'1M')});
        end
    end
end
