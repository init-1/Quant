classdef ADV < FacBase
    %ADV Average Daily (trading????) volume
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('D');  % FORCE the dateBasis to be daily
            sdate = datestr(datenum(startDate)-31, 'yyyy-mm-dd');
	        volume = o.loadItem(secIds, 'D001410430', sdate, endDate);
            volume = ftsmovavg(volume, o.DCF('M'), true);
            shares = o.loadItem(secIds, 'D001410472', sdate, endDate);
            factorTS = volume ./ shares;
        end
    end
end
