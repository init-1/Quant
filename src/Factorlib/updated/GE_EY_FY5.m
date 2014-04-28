classdef GE_EY_FY5 < GlobalEnhanced
    %GE_EY_FY5 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate) - 370*3, 'yyyy-mm-dd');
            EPS_FY3 = o.loadItem(secIds, 'D000411366', sDate, endDate);
            EPS_FY3 = backfill(EPS_FY3, o.DCF('18M'), 'entry');
            
            if o.isLive
                PR = o.loadItem(nargout>1,secIds, 'D000453775', startDate, endDate);
            else
                PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            
            gth = o.estGrowth(EPS_FY3, o.DCF('12M'), o.DCF('4M'));  % it runs in moving manner
            dates = o.genDates(startDate, endDate, o.freq);    % 'Busday', 0);
            [EPS_FY3, gth, PR] = aligndates(EPS_FY3, gth, PR, dates);
            factorTS = EPS_FY3 .* (1+gth).^2 ./ PR;
        end
    end
end
