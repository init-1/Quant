classdef GE_EV_EBIT_MOM < GlobalEnhanced
    %GE_EV_EBIT_MOM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370, 'yyyy-mm-dd');
            EBIT = o.loadItem(secIds, 'D000110473', sDate, endDate);
            EV = o.loadItem(secIds, 'D000110514', sDate, endDate);
            nbf = o.DCF('18M');
            EBIT = backfill(EBIT, nbf, 'entry');
            EV = backfill(EV, nbf, 'entry');
            EBITE = EBIT ./ EV;
            factorTS = o.diff_({o.lagfts(EBITE,'24M'),o.lagfts(EBITE,'12M'),EBITE});
        end
    end
end
