classdef GTHFY1_Base < FacBase
    %GTHFY1_Base <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09

    methods (Access = protected)
        function factorTS = define(o, currId, prevId, secIds, startDate, endDate)
            dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            curr = o.loadItem(secIds, currId, startDate, endDate);
            prev = o.loadItem(secIds, prevId, startDate, endDate);
            [curr, prev] = aligndates(curr, prev, dates);
            factorTS = (prev - curr) / (abs(prev) + abs(curr)/2);
        end
    end
end
