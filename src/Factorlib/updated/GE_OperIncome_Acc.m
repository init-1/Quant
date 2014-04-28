classdef GE_OperIncome_Acc < GlobalEnhanced
    %GE_OperIncome_Acc <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-2*370,'yyyy-mm-dd');
            OP = o.loadItem(secIds, 'D000110891', sDate, endDate);
            OP = backfill(OP, o.DCF('18M'), 'entry');
            factorTS = o.diff_({o.lagfts(OP,'24M') o.lagfts(OP,'12M') OP});
        end
    end
end
