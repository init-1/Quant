classdef GE_FCFEV_MOM < GlobalEnhanced
    %GE_FCFEV_MOM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370, 'yyyy-mm-dd');
            EV = o.loadItem(secIds, 'D000110514', sDate, endDate);
            FO = o.loadItem(secIds, 'D000110585', sDate, endDate);
            DIV = o.loadItem(secIds, 'D000110343', sDate, endDate);
            CAPEX = o.loadItem(secIds, 'D000110329', sDate, endDate);
            
            FCF_E = (FO-DIV-CAPEX)./EV;
            factorTS = o.diff_({o.lagfts(FCF_E,'24M'), o.lagfts(FCF_E,'12M'), FCF_E});
        end
    end
end
