classdef GE_FCF_EV_RIG < GlobalEnhanced
    %GE_FCF_EV_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            FFO_A = o.loadItem(secIds, 'D000110585', startDate, endDate);
            CashDiv_A = o.loadItem(secIds, 'D000110343', startDate, endDate);
            CapEx_A = o.loadItem(secIds, 'D000110329', startDate, endDate);
            EV_A = o.loadItem(secIds, 'D000110514', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            [FFO_A,CashDiv_A,CapEx_A,EV_A] = aligndates(FFO_A,CashDiv_A,CapEx_A,EV_A,gics.dates);
            
            FCF_EV_A = (FFO_A - CapEx_A - CashDiv_A) ./ EV_A;
            FCF_EV_A(isinf(fts2mat(FCF_EV_A))) = NaN;
            factorTS = o.RIG(FCF_EV_A, gics);
            factorTS = backfill(factorTS, o.DCF('12M'), 'entry');
        end
    end
end
