classdef PRCVLT < FacBase
    %PRCVLT <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:10
    
    methods (Access = protected)
        function pvt = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            window = 390;
            pvt_window = 20;
            
            % Load data here
            startDate = datenum(startDate);
            startDate_ = datestr(addtodate(startDate,-45,'M'),'yyyy-mm-dd');
            price  = o.loadItem(secIds, 'D001410415', startDate_, endDate);
            volume = o.loadItem(secIds, 'D001410430', startDate_, endDate);
            
            volume = price .* volume;  % dollar volume
            volume(isnan(volume)) = 0;
            volume_ema = tsmovavg(volume, 'e', window); % exponential moving average
            
            volume(1:window,:)     = [];     % for align daily return
            volume_ema(1:window,:) = [];
            price(1:window-1,:)    = [];
            
            pvt_daily = Price2Return(price,1) .* volume ./ volume_ema;
            
            date_daily = pvt_daily.dates;
            data_daily = fts2mat(pvt_daily);
            
            pvt = NaN(size(pvt_daily));
            data_daily(1:window,:) = bsxfun(@times, data_daily(1:window,:), 0.9 .^ (window:-1:1)');
            for t = window+1:length(date_daily)
                pvt(t,:) = nansum(data_daily(t-window:t,:),1);
                data_daily(t-window+1:t,:) = data_daily(t-window+1:t,:) .* 0.9;
            end
            
            pvt = myfints(date_daily, pvt, fieldnames(pvt_daily,1));
            pvt = ftsmovavg(pvt, pvt_window, true);  % true: ignore NaN
        end
    end
end
