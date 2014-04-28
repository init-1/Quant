classdef GE_CF_3M_Surprise_RIG < GlobalEnhanced
    %GE_CF_3M_Surprise_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-24*31, 'yyyy-mm-dd');
%             FY1   = o.loadItem(secIds, 'D000415183', sDate, endDate);
%             FY0   = o.loadItem(secIds, 'D000431933', sDate, endDate);
%             FY1        = fill(FY1, inf, 'entry');
%             FY0        = fill(FY0, inf, 'entry');
            CPS_FY1_MD = o.loadItem(secIds, 'D000410564', sDate, endDate);
            CPS_FY0_RV = o.loadItem(secIds, 'D000410138', sDate, endDate);
            CPS_FY1_MD = fill(CPS_FY1_MD, inf, 'entry');
            CPS_FY0_RV = fill(CPS_FY0_RV, inf, 'entry');
       
            if o.isLive
                EPS_FY0_PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                EPS_FY0_PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            Mon = '3M';
            surprise = o.IBES_Surprise(CPS_FY0_RV, CPS_FY1_MD, o.DCF(Mon));
            [surprise, EPS_FY0_PR] = aligndates(surprise, EPS_FY0_PR, gics.dates);
            surprise(EPS_FY0_PR<=0) = NaN;
            surprise = surprise ./ EPS_FY0_PR;
            factorTS = o.RIG(surprise, gics);
        end
    end
end
