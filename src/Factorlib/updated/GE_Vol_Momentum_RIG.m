classdef GE_Vol_Momentum_RIG < GlobalEnhanced
    %GE_Vol_Momentum_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = o.loadItem(secIds, 'D002420063', datestr(datenum(startDate)-2*31, 'yyyy-mm-dd'), endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            factorTS = aligndates(factorTS, gics.dates);
            factorTS = o.RIG(factorTS, gics);
        end
    end
end
