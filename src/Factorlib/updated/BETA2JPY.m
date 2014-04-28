classdef BETA2JPY < FacBase
    %BETA2JPY <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03
    
    methods (Access = protected)
        function FXBeta = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-3,'Y'),'yyyy-mm-dd');
            closePrice = o.loadItem(secIds, 'D001410414', sDate, endDate);
            USMarket = LoadIndexItemTS('0064984000', 'D000210568', sDate, endDate);
            JPMarket = LoadIndexItemTS('0064939200', 'D000210568', sDate, endDate);
            GLBMarket = LoadIndexItemTS('0064990100', 'D000210568', sDate, endDate);
            FXRate = LoadFXTS('JPY','USD',sDate,endDate);
            
            [USMarket, JPMarket, GLBMarket, FXRate] = aligndates(USMarket, JPMarket, GLBMarket, FXRate, closePrice.dates);
            tmpcel = {closePrice, USMarket, JPMarket, GLBMarket, FXRate};
            tenor = int32(o.DCF('M'));
            tmpcel = cellfun(@(x){Price2Return(x,tenor)},tmpcel);
            [stockRtn, USRtn, JPRtn, GLBRtn, FXRtn] = tmpcel{:};
            
            [ndate, nstock] = size(stockRtn);
            tmpdates = stockRtn.dates;
            tmpsecids = fieldnames(stockRtn,1);
            ctry = LoadSecInfo(tmpsecids,'country','','',0);
            ctry = ctry.country;
            
            stockRtn = fts2mat(stockRtn);
            USRtn = fts2mat(USRtn);
            JPRtn = fts2mat(JPRtn);
            GLBRtn = fts2mat(GLBRtn);
            FXRtn = fts2mat(FXRtn);
            
            win = int32(24 * o.DCF('M')); % 24 months regression window
            FXBeta = myfints(tmpdates, nan(ndate, nstock), tmpsecids);
            for i = 1:nstock
                switch ctry{i}
                    case 'USA'
                        mktRtn = USRtn;
                    case 'JPN'
                        mktRtn = JPRtn;
                    otherwise
                        mktRtn = GLBRtn;
                end
                for j = win:ndate % use regression to find the sensitivity to fx return, with the presence of market return
                    tmpY = stockRtn(j-win+1:j,i);
                    tmpX = [ones(win,1), mktRtn(j-win+1:j,:), FXRtn(j-win+1:j,:)];
                    beta = regress(tmpY,tmpX);
                    FXBeta(j,i) = beta(end);
                end
            end
        end
    end
end
