classdef GE_PCF_12M_RIG < GlobalEnhanced
    %GE_PCF_12M_RIG <a full descriptive name placed here>
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
            %%%%FY0 = o.loadItem(secIds, 'D000431933', startDate, endDate);
            CPS_F1_MD = o.loadItem(secIds, 'D000410564', startDate, endDate);
            CPS_F2_MD = o.loadItem(secIds, 'D000410565', startDate, endDate);
            CPS_F3_MD = o.loadItem(secIds, 'D000410566', startDate, endDate);
            
            if o.isLive
                EPS_FY0_PR = o.loadItem(secIds, 'D000453775', startDate, endDate);
            else
                EPS_FY0_PR = o.loadItem(secIds, 'D000410126', startDate, endDate);
            end
            
            gics = LoadQSSecTS(secIds, 913, 0, startDate, endDate, o.freq);
            [FY1,FY2,FY3,CPS_F1_MD,CPS_F2_MD,CPS_F3_MD,EPS_FY0_PR] = aligndates(FY1,FY2,FY3,CPS_F1_MD,CPS_F2_MD,CPS_F3_MD,EPS_FY0_PR,gics.dates);
            FWD12 = o.IBES_FWD12(FY1, FY2, FY3, CPS_F1_MD, CPS_F2_MD, CPS_F3_MD);
            FWD12(EPS_FY0_PR <= 0) = NaN;
            FWD12Yield = FWD12 ./ EPS_FY0_PR;
            factorTS = o.RIG(FWD12Yield, gics);
        end
    end
end
