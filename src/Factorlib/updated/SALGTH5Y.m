classdef SALGTH5Y < FacBase
    %SALGTH5Y <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:13
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-18,'M'),'yyyy-mm-dd');
            factorTS = o.loadItem(secIds, 'D000110852', sDate, endDate);
            factorTS = fill(factorTS, inf, 'entry');
        end
    end
end
