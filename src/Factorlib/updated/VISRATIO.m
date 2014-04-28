classdef VISRATIO < FacBase
    %VISRATIO <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:16
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            %% Parameter
            window = 50;  % daily
            sdate = datestr(datenum(startDate)-80, 'yyyy-mm-dd');
            volume = o.loadItem(secIds, 'D001410430', sdate, endDate);
            vol_sma = ftsmovavg(volume, window, true);
            factorTS = volume ./ vol_sma;
            factorTS(factorTS < 0) = nan;
        end
    end
end
