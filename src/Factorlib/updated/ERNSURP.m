classdef ERNSURP < FacBase
    %ERNSURP <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:08

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-6,'M'),'yyyy-mm-dd');
            % sDatePr = datestr(addtodate(datenum(startDate),-10,'D'),'yyyy-mm-dd');
            epsActQtr = o.loadItem(secIds,'D000432131',sDate,endDate);
            FQ0 = o.loadItem(secIds,'D000431932',sDate,endDate);
            epsEstFQ1 = o.loadItem(secIds,'D000435580',sDate,endDate);
            FQ1 = o.loadItem(secIds,'D000415179',sDate,endDate);
            % closePrice = o.loadItem(secIds,'D001410415',sDatePr,endDate);
            
            %% Calculation here USUALLY
            surprise = ibesSurprise(epsActQtr,FQ0,epsEstFQ1,FQ1);
            surprise = backfill(surprise,o.DCF('3M'),'entry');
            
            surpriseLag = o.lagfts(surprise, '3M', NaN);
            factorTS = (surprise - surpriseLag)./((abs(surprise)+abs(surpriseLag))/2);
        end
    end
end
