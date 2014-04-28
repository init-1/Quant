classdef CFROIFY1 < FacBase
    %CFROIFY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:05
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-1,'M'),'yyyy-mm-dd');
            factorTS = o.loadItem(secIds, 'D002400087', sDate, endDate);
            factorTS = fill(factorTS, inf, 'entry');
        end
        
    end
end
