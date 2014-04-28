classdef GE_CFYield_RIG < GlobalEnhanced
    %GE_CFYield_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            if o.isLive
                Close = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                Close = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
            CPS = o.loadItem(secIds, 'D000110142', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            [Close,CPS] = aligndates(Close,CPS,gics.dates);
            factorTS = CPS ./ Close;
            factorTS =  o.RIG(factorTS, gics);
            factorTS = backfill(factorTS, o.DCF('12M'), 'entry');
        end
    end
end
