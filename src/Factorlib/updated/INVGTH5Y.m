classdef INVGTH5Y  < FacBase
    %INVGTH5Y <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09
    
    methods (Access = protected)
        % build function for Class: CFROICHG
        function factorTS = build(o, secIds, startDate, endDate)
            itemid = 'D002400028';
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            factorTS = o.loadItem(secIds,itemid,sDate,endDate);
            factorTS = backfill(factorTS,o.DCF('2M'),'entry');
        end
    end
end
