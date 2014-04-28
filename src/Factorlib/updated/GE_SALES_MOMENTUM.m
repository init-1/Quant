classdef GE_SALES_MOMENTUM < GlobalEnhanced
    %GE_SALES_MOMENTUM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-200,'yyyy-mm-dd');
            SALES = o.loadItem(secIds, 'D000111513', sDate, endDate);
            factorTS = o.momentum_TL({o.lagfts(SALES,'6M') o.lagfts(SALES,'3M') SALES});
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
