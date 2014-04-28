classdef GE_Momentum12M < GlobalEnhanced
    %GE_Momentum12M <a full descriptive name placed here>
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
            PR = o.loadItem(secIds, 'D000310017', sDate, endDate);
            lagPR = o.lagfts(PR, '12M');
            factorTS = o.momentum_TR({lagPR, PR});
        end
    end
end
