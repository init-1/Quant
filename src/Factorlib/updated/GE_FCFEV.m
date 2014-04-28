classdef GE_FCFEV < GlobalEnhanced
    %GE_FCFEV <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EV = o.loadItem(secIds, 'D000110514', startDate, endDate);
            FO = o.loadItem(secIds, 'D000110585', startDate, endDate);
            DIV = o.loadItem(secIds, 'D000110343', startDate, endDate);
            CAPEX = o.loadItem(secIds, 'D000110329', startDate, endDate);
            factorTS=(FO-DIV-CAPEX)./EV;
        end
    end
end
