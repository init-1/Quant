classdef REVSAL5D < FacBase
    %REVSAL5D <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            
            sDate = datestr(addtodate(datenum(startDate),-1,'M'),'yyyy-mm-dd');
            closePrice = o.loadItem(secIds,'D001410415',sDate,endDate);
            closePrice = backfill(closePrice,o.DCF('3D'),'entry');
            factorTS = Price2Return(closePrice,o.DCF('5D'));
        end
    end
end
