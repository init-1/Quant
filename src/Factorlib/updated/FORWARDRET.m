classdef FORWARDRET < FacBase
    %FORWARDRET <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:08
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-2,'month'));
            eDate = datestr(addtodate(datenum(endDate),+2,'month'));
            
            %% Load data here (Loadxxx())
            rawData = o.loadItem(secIds,'D001410446',sDate,eDate);
            rawData = o.leadfts(rawData, '1M');
            factorTS = Price2Return(rawData,1);
        end
    end
end
