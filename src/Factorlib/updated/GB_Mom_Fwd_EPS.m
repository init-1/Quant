classdef GB_Mom_Fwd_EPS < GlobalEnhanced
    %GB_Mom_Fwd_EPS <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:21

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate, mon)
            sDate = datestr(datenum(startDate)-3*31-round(o.DCF(mon,'D')*1.5), 'yyyy-mm-dd');
            FY1 = o.loadItem(secIds, 'D000415183', sDate, endDate);
            FY2 = o.loadItem(secIds, 'D000415184', sDate, endDate);
            FY3 = o.loadItem(secIds, 'D000415185', sDate, endDate);
            %%%FY0 = o.loadItem(secIds, 'D000431933', sDate, endDate);
            EPS_F1_MD = o.loadItem(secIds, 'D000411364', sDate, endDate);
            EPS_F2_MD = o.loadItem(secIds, 'D000411365', sDate, endDate);
            EPS_F3_MD = o.loadItem(secIds, 'D000411366', sDate, endDate);
            
            FWD12 = o.IBES_FWD12(FY1, FY2, FY3, EPS_F1_MD, EPS_F2_MD, EPS_F3_MD);
            factorTS = o.momentum_TL({o.lagfts(FWD12,mon) FWD12});
        end
    end
end
