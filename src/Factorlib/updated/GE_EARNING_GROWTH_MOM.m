classdef GE_EARNING_GROWTH_MOM < GlobalEnhanced
    %GE_EARNING_GROWTH_MOM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370,'yyyy-mm-dd');
            EPS_FY1 = o.loadItem(secIds, 'D000411364', sDate, endDate);
            EPS_FY2 = o.loadItem(secIds, 'D000411365', sDate, endDate);
            nbf = o.DCF('3M');
            EPS_FY1 = backfill(EPS_FY1, nbf, 'entry');
            EPS_FY2 = backfill(EPS_FY2, nbf, 'entry');
            
            EL = EPS_FY2 - EPS_FY1;
            EL_12 = o.lagfts(EL, '12M');
            EL_24 = o.lagfts(EL, '24M');
            factorTS = (EL - EL_12) ./ max(abs(fts2mat(EL)), abs(fts2mat(EL_12)));
            factorTS_= (EL - EL_24) ./ max(abs(fts2mat(EL)), abs(fts2mat(EL_24)));
            idx = abs(factorTS) == 1e-12;
            factorTS(idx) = factorTS_(idx);
        end
    end
end
