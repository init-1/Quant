classdef CFROIVAL  < FacBase
    %CFROIVAL <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:05
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            itemid = 'D002400017';
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            factorTS = o.loadItem(secIds,itemid,sDate,endDate);
            factorTS = backfill(factorTS,o.DCF('2M'),'entry');
        end
    end
end
