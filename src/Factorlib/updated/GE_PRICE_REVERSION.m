classdef GE_PRICE_REVERSION < GlobalEnhanced
    %GE_PRICE_REVERSION <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:25

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            sDate = datestr(datenum(startDate)-90,'yyyy-mm-dd');
            RI = o.loadItem(secIds, 'D000310017', sDate, endDate);
            factorTS = o.VF(RI, 15, 60);
        end
        
        function r = VF(o, x, mom_win, sig_win)
        % May need to consider NaN further in the future
            ret = log(x);
            ret = ret - o.lagfts(ret, '1D');
            
            sigma = ftsmovfun(ret, sig_win, @(x)nanstd(x,[],1)) .* sqrt(o.DCF('Y'));
            sigma(sigma < 0.2) = 0.2;
            mind = ftsmovfun(x, mom_win, @(x)min(x,[],1));
            maxd = ftsmovfun(x, mom_win, @(x)max(x,[],1));
            r = (x -(mind+maxd)/2) ./ maxd ./ sigma;
        end
    end
end
