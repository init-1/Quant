classdef GE_ROIC_MOMENTUM < GlobalEnhanced
    %GE_ROIC_MOMENTUM <a full descriptive name placed here>
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
            ROIC = o.loadItem(secIds, 'D000111158', sDate, endDate);
            ROIC = backfill(ROIC, o.DCF('18M'), 'entry');
            factorTS = o.momentum_TL({o.lagfts(ROIC,'24M') o.lagfts(ROIC,'12M') ROIC});
        end
    end
end
