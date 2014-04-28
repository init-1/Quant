classdef GE_PSAL_12M_RIG < GlobalEnhanced
    %GE_PSAL_12M_RIG <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            FY1 = o.loadItem(secIds, 'D000415183', startDate, endDate);
            FY2 = o.loadItem(secIds, 'D000415184', startDate, endDate);
            FY3 = o.loadItem(secIds, 'D000415185', startDate, endDate);
            %%%FY0 = o.loadItem(secIds, 'D000431933', startDate, endDate);
            SAL_F1_MD = o.loadItem(secIds, 'D000412644', startDate, endDate);
            SAL_F2_MD = o.loadItem(secIds, 'D000412645', startDate, endDate);
            SAL_F3_MD = o.loadItem(secIds, 'D000412646', startDate, endDate);
            
            if o.isLive
                EPS_FY0_PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                EPS_FY0_PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            
            EPS_FY0_NS = o.loadItem(secIds, 'D000453774', startDate, endDate);
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            
            [FY1,FY2,FY3,SAL_F1_MD,SAL_F2_MD,SAL_F3_MD,EPS_FY0_PR,EPS_FY0_NS] = aligndates(FY1,FY2,FY3,SAL_F1_MD,SAL_F2_MD,SAL_F3_MD,EPS_FY0_PR,EPS_FY0_NS,gics.dates);
            FWD12 = o.IBES_FWD12(FY1, FY2, FY3, SAL_F1_MD, SAL_F2_MD, SAL_F3_MD);
            FWD12(fts2mat(EPS_FY0_PR) <= 0 | fts2mat(EPS_FY0_NS) <= 0) = NaN;
            FWD12Yield = FWD12 ./ (EPS_FY0_PR .* EPS_FY0_NS);
            factorTS = o.RIG(FWD12Yield, gics);
        end
    end
end
