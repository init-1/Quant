classdef GE_ValueCreationChg < GlobalEnhanced
    %GE_ValueCreationChg <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sdate = datestr(datenum(startDate)-2*31, 'yyyy-mm-dd');
            GRA_FY0 = o.loadItem(secIds, 'D002400029', sdate, endDate);
            CFROI_FY0 = o.loadItem(secIds, 'D002400051', sdate, endDate);
            GRA_FY1 = o.loadItem(secIds, 'D002400080', sdate, endDate);
            GRA_FY2 = o.loadItem(secIds, 'D002400081', sdate, endDate);
            CFROI_FY1 = o.loadItem(secIds, 'D002400087', sdate, endDate);
            CFROI_FY2 = o.loadItem(secIds, 'D002400088', sdate, endDate);
            DR_FY0 = o.loadItem(secIds, 'D002400100', sdate, endDate);
            DR_FY1 = o.loadItem(secIds, 'D002400101', sdate, endDate);
            DR_FY2 = o.loadItem(secIds, 'D002400102', sdate, endDate);
            factorTS = 0.6*((CFROI_FY0-DR_FY0).*GRA_FY0) + 0.3*((CFROI_FY1-DR_FY1).*GRA_FY1) + 0.1*((CFROI_FY2-DR_FY2).*GRA_FY2);
        end
    end
end
