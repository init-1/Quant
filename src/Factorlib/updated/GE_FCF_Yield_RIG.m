classdef GE_FCF_Yield_RIG < GlobalEnhanced
    %GE_FCF_Yield_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            FCFPS = o.loadItem(secIds, 'D000110237', startDate, endDate);
            if o.isLive
                Close = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                Close = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [FCFPS,Close] = aligndates(FCFPS,Close,gics.dates);
            factorTS = FCFPS ./ Close;
            factorTS(isinf(fts2mat(factorTS))) = NaN;
            factorTS = o.RIG(factorTS, gics);
            factorTS = backfill(factorTS, o.DCF('12M'), 'entry');
        end
    end
end
