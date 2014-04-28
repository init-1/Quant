classdef RELSTH < FacBase
    %RELSTH <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            %% Parameter
            window = 260;   % 1 year
            
            sdate = datestr(datenum(startDate)-366, 'yyyy-mm-dd');
            price = o.loadItem(secIds, 'D001410415', sdate, endDate);
            
            f = @(x) nanmax(x,[], 1);
            maxes = ftsmovfun(price, window, f);
            
            factorTS = price ./ maxes;
        end
    end
end
