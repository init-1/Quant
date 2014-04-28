classdef GE_DPS_3M_Surprise_RIG < GlobalEnhanced
    %GE_DPS_3M_Surprise_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-18*31, 'yyyy-mm-dd');
%             FY1 = o.loadItem(secIds, 'D000415183', sDate, endDate);
%             FY0 = o.loadItem(secIds, 'D000431933', sDate, endDate);
%             FY1        = backfill(FY1, 36, 'entry');
%             FY0        = backfill(FY0, 36, 'entry');
            DPS_FY1_MD = o.loadItem(secIds, 'D000410724', sDate, endDate);
            DPS_FY0_RV = o.loadItem(secIds, 'D000410146', sDate, endDate);
            nbf = o.DCF('36M');
            DPS_FY1_MD = backfill(DPS_FY1_MD, nbf, 'entry');
            DPS_FY0_RV = backfill(DPS_FY0_RV, nbf, 'entry');
            
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            Mon = '3M';
            surprise = o.IBES_Surprise(DPS_FY0_RV, DPS_FY1_MD, o.DCF(Mon));
            surprise = aligndates(surprise, gics.dates);
            factorTS = o.RIG(surprise, gics);
        end
    end
end
