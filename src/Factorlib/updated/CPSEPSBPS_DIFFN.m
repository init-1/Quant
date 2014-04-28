classdef CPSEPSBPS_DIFFN < FacBase
    %CPSEPSBPS_DIFFN <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:05
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            EPSdiffn = create(DIFFN,o.isLive,o.freq,secIds,startDate,endDate);
            BPSdiffn = create(DIFFNBPS,o.isLive,o.freq,secIds,startDate,endDate);
            CPSdiffn = create(DIFFNCPS,o.isLive,o.freq,secIds,startDate,endDate);
            factorTS = ftsnanmean(BPSdiffn,CPSdiffn,EPSdiffn);
        end
        
        function factorTS = buildLive(o, secIds, runDate)
            EPSdiffn = create(DIFFN,o.isLive,secIds,runDate);
            BPSdiffn = create(DIFFNBPS,o.isLive,secIds,runDate);
            CPSdiffn = create(DIFFNCPS,o.isLive,secIds,runDate);
            factorTS = ftsnanmean(BPSdiffn,CPSdiffn,EPSdiffn);
        end
    end
end
