classdef GE_REV_RATIO < GlobalEnhanced
    %GE_REV_RATIO <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-3*31, 'yyyy-mm-dd');
            EPS_F1_DN = o.loadItem(secIds, 'D000411374', sDate, endDate);
            EPS_F1_NE = o.loadItem(secIds, 'D000411384', sDate, endDate);
            EPS_F1_UP = o.loadItem(secIds, 'D000411394', sDate, endDate);
            nbf = o.DCF('3M');
            EPS_F1_DN = backfill(EPS_F1_DN, nbf, 'entry');
            EPS_F1_NE = backfill(EPS_F1_NE, nbf, 'entry');
            EPS_F1_UP = backfill(EPS_F1_UP, nbf, 'entry');
            
            EPS_F1_NE(EPS_F1_NE == 0) = NaN;
            factorTS = (EPS_F1_UP-EPS_F1_DN)./EPS_F1_NE;
        end
    end
end
