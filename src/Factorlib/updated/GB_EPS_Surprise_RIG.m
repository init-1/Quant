classdef GB_EPS_Surprise_RIG < GlobalEnhanced
    %GB_EPS_Surprise_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate, Mon)
            sDate = datestr(datenum(startDate)-15*31-round(o.DCF(Mon,'D')*1.5), 'yyyy-mm-dd');
%             FY1 = o.loadItem(secIds, 'D000415183', sDate, endDate);
%             FY0 = o.loadItem(secIds, 'D000431933', sDate, endDate);
%             FY1        = backfill(FY1, inf, 'entry');
%             FY0        = backfill(FY0, inf, 'entry');
            EPS_FY1_MD = o.loadItem(secIds, 'D000411364', sDate, endDate);
            EPS_FY0_RV = o.loadItem(secIds, 'D000410178', sDate, endDate);
            EPS_FY1_MD = fill(EPS_FY1_MD, inf, 'entry');
            EPS_FY0_RV = fill(EPS_FY0_RV, inf, 'entry');
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            surprise = o.IBES_Surprise(EPS_FY0_RV, EPS_FY1_MD, o.DCF(Mon));
            surprise = aligndates(surprise, gics.dates);
            factorTS = o.RIG(surprise, gics);
        end
    end
end
