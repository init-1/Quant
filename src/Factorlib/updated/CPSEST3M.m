classdef CPSEST3M < IBESCHG_Base
    %CPSEST3M <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:05
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            nMonth = 3;
            FY1DataId = 'D000434784';
            FY2DataId = 'D000434785';
            FY1PeriodId = 'D000415183';
            FY2PeriodId = 'D000415184';
            factorTS = build@IBESCHG_Base(o, secIds, startDate, endDate, nMonth, FY1DataId, FY2DataId, FY1PeriodId, FY2PeriodId);
        end
    end
end
