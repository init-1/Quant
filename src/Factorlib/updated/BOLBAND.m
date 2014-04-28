classdef BOLBAND < FacBase
    %BOLBAND <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:04

    properties (Constant)
        LengthOfSubPeriod = 60;  % daily
    end
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('D');  % FORCE to calculate in daily no matter what frequency required
            sdate = datestr(datenum(startDate)-100, 'yyyy-mm-dd');
            price = o.loadItem(secIds, 'D001410415', sdate, endDate);
            sma60 = ftsmovavg(price, o.LengthOfSubPeriod, true);
            std60 = ftsmovstd(price, o.LengthOfSubPeriod, true);
            factorTS = (price - sma60 - 2*std60) / (4*std60);
        end
    end
end
