classdef ASSETGR  < FacBase
    %ASSETGR <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            itemid = 'D002400029';  % Growth_Rate_Asset_FY0
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            factorTS = o.loadItem(secIds,itemid,sDate,endDate);
            factorTS = backfill(factorTS,o.DCF('2M'),'entry');
        end
    end
end