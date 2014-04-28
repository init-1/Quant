classdef EARGTH5Y < FacBase
    %EARGTH5Y <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-18,'M'),'yyyy-mm-dd');
            factorTS = o.loadItem(secIds, 'D000110479', sDate, endDate);
            factorTS = fill(factorTS, inf, 'entry');
        end
    end
end
