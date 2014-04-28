classdef EXTFIN < FacBase
    %EXTFIN <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:08
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-18,'M'),'yyyy-mm-dd');
            sDates = o.genDates(sDate, endDate, o.freq);
            extFinItem = 'D000110538';
            totAssetItem = 'D000111193';
            extFin = o.loadItem(secIds,extFinItem,sDate,endDate);
            totAsset = o.loadItem(secIds,totAssetItem,sDate,endDate);
            [extFin, totAsset] = aligndata(extFin, totAsset, sDates);

            nbf = o.DCF('12M');
            extFin = backfill(extFin, nbf, 'entry');
            totAsset = backfill(totAsset, nbf, 'entry');
            factorTS = extFin./totAsset;
        end
    end
end
