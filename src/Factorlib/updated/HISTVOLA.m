classdef HISTVOLA < FacBase
    %HISTVOLA <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            sdate = datestr(datenum(startDate)-400, 'yyyy-mm-dd');
            ret = Price2Return(o.loadItem(secIds, 'D001410415', sdate, endDate),1);
            factorTS = ftsmovstd(ret, o.DCF('Y'), true);
        end
    end
end
