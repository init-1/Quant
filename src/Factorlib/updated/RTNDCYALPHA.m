classdef RTNDCYALPHA < FacBase
    %RTNDCYALPHA <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:12

    properties (Constant)
        INDEX_ID = '00053';
    end
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            nRegPoints = 12;
            decayConst = 0.322;
            
            sdate = datestr(datenum(startDate)-nRegPoints*31, 'yyyy-mm-dd');
            price = o.loadItem(secIds, 'D001410415', sdate, endDate);
            ret   = Price2Return(price, o.DCF('M'));
            
            index   = LoadIndexItemTS(o.INDEX_ID, 'D001400028', sdate, endDate, o.dateBasis.freqBasis);
            ret_idx = Price2Return(index, o.DCF('M'));
            
            ret_idx = aligndates(ret_idx, ret.dates);
            
            [nDates, nStocks] = size(ret);
            beta  = nan(1, nStocks);
            factorTS = ret;
            factorTS(1:11,:) = nan;
            
            decayCoef = (decayConst ./ (1:nRegPoints))';
            for t = 12:nDates
                range = t-nRegPoints+1:t;
                yall = bsxfun(@times, ret(range,:), decayCoef);
                for i = 1:nStocks
                    FTSASSERT(isidenticaldates(ret(range,i), ret_idx(range,:)));
                    y = fts2mat(yall(:,i));
                    x = fts2mat(ret_idx(range,:));
                    if all(isnan(y)) || all(isnan(x))
                        beta(i) = nan;
                    else
                        beta(i) = regress(y, x);
                    end
                end
                
                alpha = bsxfun(@minus, yall, bsxfun(@times, beta, ret_idx(range,:)));
                factorTS(t,:) = uniftsfun(alpha, @(x) nanmean(x,1));
            end
        end
    end
end
