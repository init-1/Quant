classdef GE_PE_FY5_RIG < GlobalEnhanced
    %GE_PE_FY5_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-4*370, 'yyyy-mm-dd');
            EPS_FY3 = o.loadItem(secIds, 'D000411366', sDate, endDate);
            EPS_FY3 = fill(EPS_FY3, inf, 'entry');
            
            if o.isLive
                EPS_FY0_PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                EPS_FY0_PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            FY5 = o.estGrowth(EPS_FY3,o.DCF('12M'),o.DCF('4M'));
            
            [FY5, EPS_FY3, EPS_FY0_PR] = aligndates(FY5, EPS_FY3, EPS_FY0_PR, gics.dates);
            FY5 = EPS_FY3 .* (1+FY5) .^ 2;
            FY5 = FY5 ./ EPS_FY0_PR;
            FY5(EPS_FY0_PR <= 0) = NaN;
            factorTS = o.RIG(FY5, gics);
        end
    end
end
