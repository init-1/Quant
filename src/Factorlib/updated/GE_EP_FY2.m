classdef GE_EP_FY2 < GlobalEnhanced
    %GE_EP_FY2 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:23

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-3*370, 'yyyy-mm-dd');
            EPS = o.loadItem(secIds, 'D000110211', sDate, endDate);
            EPS = backfill(EPS, o.DCF('15M'), 'entry');
            
            if o.isLive
                PR = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
                        
            factorTS = (1+o.estGrowth(EPS,o.DCF('12M'),o.DCF('3M'))).^2;
            dates = o.genDates(startDate, endDate, o.freq);
            [factorTS, EPS, PR] = aligndates(factorTS, EPS, PR, dates);
            factorTS = factorTS .* EPS ./ PR;
        end
    end
end
