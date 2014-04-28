classdef DPSEST3M < IBESCHG_Base
    %BPSEST3M DPS 3M estimated change
    %
    %  See IBESCHG_Base for details.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:04
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            nMonth = 3;
            FY1DataId = 'D000434944';
            FY2DataId = 'D000434945';
            FY1PeriodId = 'D000415183';
            FY2PeriodId = 'D000415184';
            
            factorTS = build@IBESCHG_Base(o, secIds, startDate, endDate, nMonth, FY1DataId, FY2DataId, FY1PeriodId, FY2PeriodId);
        end
    end
end
