classdef IBESCHG_Base < FacBase
    %IBESCHG_Base <a full descriptive name placed here>
    %
    %  Formula:
    %    {3 Months Changes in IBES Recom Level} = {Recom Level_current} / {Recom Level}_{3 months lag} - 1
    %
    %  Description:
    %    Simple recommendations from IBES still works
    %
    %  Descendents: BPSEST3M, DPSEST3M
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate, nMonth, FY1DataId, FY2DataId, FY1PeriodId, FY2PeriodId)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate), -6, 'M'),'yyyy-mm-dd');
            FY1Data = o.loadItem(secIds,FY1DataId,sDate,endDate);
            FY2Data = o.loadItem(secIds,FY2DataId,sDate,endDate);
            FY1Period = o.loadItem(secIds,FY1PeriodId,sDate,endDate);
            FY2Period = o.loadItem(secIds,FY2PeriodId,sDate,endDate);
            
            %% Calculation
            factorTS = ibesEstChg(FY1Data, FY1Period, FY2Data, FY2Period, o.DCF([num2str(nMonth) 'M']));
            
            %% Data processing (backfill())
            factorTS = fill(factorTS, inf, 'entry');
        end
    end
end
