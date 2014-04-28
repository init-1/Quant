classdef LIQERNGS < FacBase
    %LIQERNGS <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            EPS = o.loadItem(secIds,'D002000016',sDate,endDate,4);
            trdVol = o.loadItem(secIds,'D001410431',sDate,endDate);
            closePrc = o.loadItem(secIds,'D001410415',sDate,endDate);
            
            %% calculate total earnings over past one year and dollar volume
            EPS_Sum = ftsnanmean(EPS{1:4})*4;
            EPS_Sum = backfill(EPS_Sum,o.DCF('3M'),'entry');

            dollarVol = trdVol .* closePrc ./ 1000000;
            factorTS = EPS_Sum ./ closePrc / dollarVol;
        end
    end
end
