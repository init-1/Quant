classdef M3CHGIBES < FacBase
    %M3CHGIBES <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-4,'M'),'yyyy-mm-dd');
            recLevel = o.loadItem(secIds, 'D000415172', sDate, endDate);
            recLevel = backfill(recLevel, o.DCF('2M'), 'entry');
            factorTS = -(recLevel./o.lagfts(recLevel, '3M', NaN) - 1);
        end
    end
end
