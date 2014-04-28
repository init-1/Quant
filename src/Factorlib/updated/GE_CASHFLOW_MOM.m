classdef GE_CASHFLOW_MOM < GlobalEnhanced
    %GE_CASHFLOW_MOM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-3*370,'yyyy-mm-dd');
            CPS_Q = o.loadItem(secIds, 'D000111623', sDate, endDate);
            CPS_A = o.loadItem(secIds, 'D000110142', sDate, endDate);
            CPS_Q = backfill(CPS_Q, o.DCF('6M'), 'entry');
            CPS_A = backfill(CPS_A, o.DCF('18M'), 'entry');
            CPS = CPS_Q;
            index = isnan(fts2mat(CPS));
            CPS(index) = CPS_A(index);
            
            CPS_12 = o.lagfts(CPS, '12M');
            CPS_24 = o.lagfts(CPS, '24M');
            factorTS = (CPS - CPS_12) ./ max(abs(fts2mat(CPS)), abs(fts2mat(CPS_12)));
            factorTS_= (CPS - CPS_24) ./ max(abs(fts2mat(CPS)), abs(fts2mat(CPS_24)));
            idx = abs(factorTS) < o.epsilon;
            factorTS(idx) = factorTS_(idx);
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
