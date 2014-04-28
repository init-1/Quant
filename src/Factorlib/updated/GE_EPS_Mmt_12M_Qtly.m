classdef GE_EPS_Mmt_12M_Qtly < GlobalEnhanced
    %GE_EPS_Mmt_12M_Qtly <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-16*31, 'yyyy-mm-dd');
            EPS_Q = o.loadItem(secIds, 'D000111453', sDate, endDate);
            EPS_Q = backfill(EPS_Q, o.DCF('6M'), 'entry');
            
            factorTS = o.momentum_TL({o.lagfts(EPS_Q,'12M') EPS_Q});
            factorTS = backfill(factorTS, o.DCF('M'), 'entry');
        end
    end
end
