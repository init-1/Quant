classdef MACD < FacBase
    %MACD <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:10
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            o.dateBasis = DateBasis('BD');
            sDate = datestr(addtodate(datenum(startDate),-5,'M'),'yyyy-mm-dd');
            closePrice = o.loadItem(secIds,'D001410415',sDate,endDate);
            
            closePrice = backfill(closePrice, o.DCF('7D'), 'entry');
            
            lagShort = 12;
            lagLong = 26;
            lagSignal = 9;
            % macd = tsmovavg(closePrice, 'e', lagShort) - tsmovavg(closePrice, 'e', lagLong);
            % macd = macd(lagLong:end,:);
            % signal = tsmovavg(macd,'e',lagSignal);
            
            macd = ftsema(closePrice, lagShort, 0) - ftsema(closePrice, lagLong, 0);
            macd = macd(lagLong:end,:);
            signal = ftsema(closePrice,lagSignal,0);
            
            [macd,signal,closePrice] = aligndates(macd,signal,closePrice,'D');
            factorTS = (macd - signal)./closePrice;
        end
    end
end
