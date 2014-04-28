classdef GE_EARNING_ACC < GlobalEnhanced
    %GE_EARNING_ACC <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-370, 'yyyy-mm-dd');
            EPS_FY1 = o.loadItem(secIds, 'D000411364', sDate, endDate);
            EPS_FY0 = o.loadItem(secIds, 'D000410178', sDate, endDate);
            EPS_FY1 = backfill(EPS_FY1, o.DCF('2M'), 'entry');
            EPS_FY0 = backfill(EPS_FY0, o.DCF('2M'), 'entry');
            
            EG = o.momentum_TL({EPS_FY0, EPS_FY1});
            factorTS = o.diff_({o.lagfts(EG,'12M') EG});
        end
    end
end
