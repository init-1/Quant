classdef RESREVL < FacBase
    %RESREVL <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            closePrice = o.loadItem(secIds, 'D001410415', sDate, endDate);
            indexPrice = LoadIndexItemTS('00053', 'D000800522', sDate, endDate);
            
            if ~iscell(secIds), secIds = {secIds}; end
            ctry = LoadSecInfo(secIds, 'country', sDate, endDate, 0);
            ctry = ctry.country;
            if nansum(ismember(ctry,{'USA','CAN'})) > 0
                predBeta = o.loadItem(secIds, 'D001500001', sDate, endDate);
                predBeta(isnan(fts2mat(predBeta))) = 1;
            else
                [Ndates, Nsec] = size(closePrice);
                predBeta = myfints(closePrice.dates,ones(Ndates,Nsec),secIds);
            end
            
            closePrice = backfill(closePrice,5,'entry');
            indexPrice = backfill(indexPrice,5,'entry');
            stockRtn = Price2Return(closePrice,20);
            indexRtn = Price2Return(indexPrice,20);
            
            %% Resample data here (aligndates())
            [stockRtn, indexRtn, predBeta] = aligndates(stockRtn, indexRtn, predBeta, o.freq);
            [stockRtn, predBeta] = alignfields(stockRtn, predBeta);
            predBeta = backfill(predBeta,2,'entry');
            
            %% Calculation here USUALLY
            factorTS = bsxfun(@times, predBeta, indexRtn) - stockRtn;
        end
    end
end
