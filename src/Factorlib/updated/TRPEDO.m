classdef TRPEDO < FacBase
    %TRPEDO <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:16
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(addtodate(datenum(startDate),-18,'M'),'yyyy-mm-dd');
            sDatePr = datestr(addtodate(datenum(startDate),-10,'D'),'yyyy-mm-dd');
            epsActQtr = o.loadItem(secIds,'D000432131',sDate,endDate);
            fq0 = o.loadItem(secIds,'D000431932',sDate,endDate);
            epsEstFQ1 = o.loadItem(secIds,'D000435580',sDate,endDate);
            fq1 = o.loadItem(secIds,'D000415179',sDate,endDate);
            closePrice = o.loadItem(secIds,'D001410415',sDatePr,endDate);
            factorTS = o.calculation(epsActQtr,fq0,epsEstFQ1,fq1,closePrice);
        end
        
        function factorTS = calculation(o, act,fq0,est,fq1,closePrice)
            % calculation function for Torpedo: it calculates the difference between
            % the IBES analyst's FQ1 eps forecast and the actual eps for the same
            % quater last year
            FTSASSERT(isaligneddata(act,fq0,est,fq1),'At least one input myfints is not aligned with others');
            
            dates = act.dates;
            actData = fts2mat(act);
            fq0Data = fts2mat(fq0);
            estData = fts2mat(est);
            fq1Data = fts2mat(fq1);
            fq1Lag = arrayfun(@(d) addtodate(d, -1, 'Y'), fq1Data);
            [r,c] = size(actData);
            
            resData = nan(r,c);
            
            % for each entry in est: find the latest observation in act where fq0 = fq1 - 1 year, and
            % fq0.dates < fq1.dates
            for j = 1:c
                for i = 1:r
                    idx = find((year(fq0Data(:,j)) == year(fq1Lag(i,j)) & month(fq0Data(:,j)) == month(fq1Lag(i,j)))& dates < dates(i),1,'last');
                    if ~isempty(idx)
                        resData(i,j) = actData(idx,j) - estData(i,j);
                    end
                end
            end
            
            torpedo = myfints(dates, resData, fieldnames(act,1), act.freq);
            
            [torpedo, closePrice] = aligndata(torpedo, closePrice);
            torpedo = backfill(torpedo, o.DCF('2M'), 'entry');
            factorTS = torpedo./closePrice;
        end
    end
end
