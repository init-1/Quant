classdef GE_Momentum12M_TR < GlobalEnhanced
    %GE_Momentum12M_TR <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-370, 'yyyy-mm-dd');
            PR = o.loadItem(secIds, 'D000310006', sDate, endDate);
            PR_1 = o.lagfts(PR, '1M');
            PR_12 = o.lagfts(PR, '12M');
            factorTS = o.momentum_TL({PR_12, PR_1});
        end
    end
end
