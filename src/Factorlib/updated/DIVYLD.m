classdef DIVYLD < FacBase
    %DIVYLD <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:06

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            nQtrs = 4;
            sDate = datestr(addtodate(datenum(startDate),-6,'M'),'yyyy-mm-dd');
            DPSQ = o.loadItem(secIds,'D000679555',sDate,endDate,nQtrs); % PIT dps
            
            sDatePr = datestr(addtodate(datenum(startDate),-10,'D'),'yyyy-mm-dd');
            closePrice = o.loadItem(secIds,'D001410415',sDatePr,endDate);
            
            DPSSum = ftsnansum(DPSQ{:});
            DPSSum = backfill(DPSSum,o.DCF('3M'),'entry');
            
            %% Calculation here USUALLY
            [DPSSum, closePrice] = aligndates(DPSSum, closePrice, o.freq);
            factorTS = DPSSum ./ closePrice;
        end
    end
end
