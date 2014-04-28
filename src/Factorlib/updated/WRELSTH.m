classdef WRELSTH < FacBase
    %WRELSTH <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:16
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            sDate = datestr(addtodate(datenum(startDate),-16,'M'),'yyyy-mm-dd');
            index = LoadIndexItemTS('007535329','D001400028',sDate,endDate);
            closePrice = o.loadItem(secIds,'D001410415',sDate,endDate);

            indexRtn = Price2Return(index,60);
            stockRtn = Price2Return(closePrice,60);
            indexRtnLag = Price2Return(o.lagfts(index,60, NaN), 200);
            stockRtnLag = Price2Return(o.lagfts(closePrice,60, NaN), 200);
            
            [indexRtn, stockRtn, indexRtnLag, stockRtnLag] = aligndates(indexRtn, stockRtn, indexRtnLag, stockRtnLag);
            factorTS = 100*bsxfun(@minus, (stockRtn + stockRtnLag),(indexRtn + indexRtnLag))/2;
        end
    end
end
