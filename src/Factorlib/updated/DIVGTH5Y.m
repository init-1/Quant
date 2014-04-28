classdef DIVGTH5Y < FacBase
    %DIVGTH5Y Dividend Per Share - 5 year annual growth
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:06
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-18,'M'),'yyyy-mm-dd');
            factorTS = o.loadItem(secIds, 'D000110467', sDate, endDate);
            %%%%factorTS = fill(factorTS, inf, 'entry');  %????
        end
    end
end
