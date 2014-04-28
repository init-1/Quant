classdef GE_REV_RATIO_MOM < GlobalEnhanced
    %GE_REV_RATIO_MOM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370, 'yyyy-mm-dd');
            F1_DN = o.loadItem(secIds, 'D000411374', sDate, endDate);
            F1_NE = o.loadItem(secIds, 'D000411384', sDate, endDate);
            F1_UP = o.loadItem(secIds, 'D000411394', sDate, endDate);

            nbf = o.DCF('3M');
            F1_DN = backfill(F1_DN, nbf, 'entry');
            F1_NE = backfill(F1_NE, nbf, 'entry');
            F1_UP = backfill(F1_UP, nbf, 'entry');
            
            F1_NE(F1_NE==0) = NaN;
            REV = (F1_UP-F1_DN)./F1_NE;
            factorTS = o.momentum_TL({o.lagfts(REV,'24M') o.lagfts(REV,'12M') REV});
        end
    end
end
