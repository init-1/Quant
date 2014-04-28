classdef ASCHG < FacBase
    %ASCHG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-5,'Y'),'yyyy-mm-dd');
            assetItem = 'D000111193';
            asset = o.loadItem(secIds, assetItem, sDate, endDate);
            asset = backfill(asset, o.DCF('18M'), 'entry');
            
            %% Calculation here USUALLY
            factorTS = asset./o.lagfts(asset, '36M',  NaN) - 1;
            factorTS = fill(factorTS, Inf, 'entry');
        end
    end
end
