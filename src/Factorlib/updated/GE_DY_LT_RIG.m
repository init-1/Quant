classdef GE_DY_LT_RIG < GlobalEnhanced
    %GE_DY_LT_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:22

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-8*370, 'yyyy-mm-dd');
            DPS = o.loadItem(secIds, 'D000110162', sDate, endDate);
            if o.isLive
                Close = o.loadItem(secIds, 'D000110013', startDate, endDate);
            else
                Close = o.loadItem(secIds, 'D000112587', startDate, endDate);
            end
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            factorTS = o.estGrowth(DPS,o.DCF('12M'),o.DCF('6M'));
            [factorTS, DPS, Close] = aligndates(factorTS, DPS, Close, gics.dates);
            factorTS = DPS .* ((1+factorTS).^5);
            factorTS(Close <= 0) = NaN;
            factorTS = factorTS ./ Close;
            factorTS = o.RIG(factorTS, gics);
        end
    end
end
