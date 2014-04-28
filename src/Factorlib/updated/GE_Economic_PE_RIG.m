classdef GE_Economic_PE_RIG < GlobalEnhanced
    %GE_Economic_PE_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:24

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sdate = datestr(datenum(startDate)-2*31, 'yyyy-mm-dd');
            CFROI = o.loadItem(secIds, 'D002400017', sdate, endDate);
            VCR = o.loadItem(secIds, 'D002400018', sdate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [CFROI, VCR] = aligndates(CFROI, VCR, gics.dates);
            factorTS = (CFROI/100)./VCR;
            factorTS(VCR == 0) = NaN;
            factorTS = o.RIG(factorTS, gics);
        end
    end
end
