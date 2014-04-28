classdef GE_Bret1_RIG < GlobalEnhanced
    %GE_Bret1_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            factorTS = o.loadItem(secIds, 'D002420042', datestr(datenum(startDate)-2*31, 'yyyy-mm-dd'), endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [factorTS, gics] = aligndates(factorTS, gics, o.freq);
            factorTS = o.RIG(factorTS, gics);
        end
    end
end
