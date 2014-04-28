classdef GE_PE_FY0_RIG < GlobalEnhanced
    %GE_PE_FY0_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EPS_A = o.loadItem(secIds, 'D000110193', startDate, endDate);
            EPS_Q = o.loadItem(secIds, 'D000111622', startDate, endDate);
            if o.isLive
                Close = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                Close = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [EPS_A,EPS_Q,Close] = aligndates(EPS_A,EPS_Q,Close,gics.dates);
            EPS = EPS_Q;
            idx = isnan(fts2mat(EPS));
            EPS(idx) = EPS_A(idx);
            factorTS = EPS./Close;
            factorTS = o.RIG(factorTS, gics);
            factorTS = backfill(factorTS, o.DCF('2M'), 'entry');
        end
    end
end
