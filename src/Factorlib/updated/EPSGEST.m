classdef EPSGEST < FacBase
    %EPSGEST <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            LTG = o.loadItem(secIds,'D000435589',sDate,endDate);
            factorTS = backfill(LTG,o.DCF('2M'),'entry')./100;
        end
        
        function factorTS = buildLive(o, secIds, endDate)
            sDate = datestr(addtodate(datenum(endDate),-2,'M'),'yyyy-mm-dd');
            LTG = o.loadItem(secIds,'D000448970',sDate,endDate);
            factorTS = LTG./100; % no need backfill since aligndates outside in FacBase whill do this
        end
    end
end
