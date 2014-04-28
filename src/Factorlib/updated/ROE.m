classdef ROE < ROE_Base
    %ROE <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:12

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
          sDate = datestr(datenum(startDate)-400, 'yyyy-mm-dd');   % -366
          netincome = o.loadItem(secIds, 'D000686576', sDate, endDate, 4);
          factorTS = build@ROE_Base(o, secIds, sDate, endDate, netincome);
        end
    end
end
