classdef CSKWNS < FacBase
    %CSKWNS <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:05
    
    properties (Constant)
        INDEX_ID = '00053';
    end
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            window = o.DCF('60M');
            
            sdate = datestr(double(datenum(startDate)-window*31), 'yyyy-mm-dd');
            price = o.loadItem(secIds, 'D001410415', sdate, endDate);
            ret   = Price2Return(price, o.DCF('M'));
            
            index   = LoadIndexItemTS(o.INDEX_ID, 'D001400028', sdate, endDate);
            index   = aligndates(index, price.dates);
            ret_idx = Price2Return(index, o.DCF('M'));
            
            %% Calculation
            ret_avg = ftsmovavg(ret, window, true);  % true means ignore NaNs
            ret_idx_avg = ftsmovavg(ret_idx, window, true);
            
            idx_disp = (ret_idx - ret_idx_avg);
            idx_disp_2 = idx_disp .* idx_disp;
            idx_disp_3 = idx_disp_2 .* idx_disp;
            
            factorTS = bsxfun(@rdivide, ftsmovsum(bsxfun(@times, ret-ret_avg, idx_disp_2), window), ftsmovsum(idx_disp_3, window));
        end
    end
end
