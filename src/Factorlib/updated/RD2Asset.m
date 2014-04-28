classdef RD2Asset < FacBase
    %RD2Asset <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            SDate = datestr(addtodate(datenum(startDate),-16,'M'),'yyyy-mm-dd');
            RnD = o.loadItem(secIds,'D000111132',SDate,endDate);
            Asset = o.loadItem(secIds,'D000111193',SDate,endDate);
            
            nbf = o.DCF('16M');
            RnD = backfill(RnD,nbf,'entry');
            Asset = backfill(Asset,nbf,'entry');
            
            RnD = RnD(min(end,5):end);
            Asset = Asset(min(end,5):end);
            
            %% Step 3: calculate factor value
            factorTS = RnD./Asset;
        end
    end
end
