function Result = CalcPeriodToDateResult(TSResult, StartDate, EndDate, method, FieldToSum, FieldToAvg)

if nargin < 5
    switch lower(method)
        case 'signalpf'
            FieldToSum = {'actRtn','alphaCappedRtn','alphaRtn','alpha_contrib','factorRtn','factor_contrib','error_contrib','constraint_contrib','stock_contrib','stock_constr_contrib','stock_alpha_contrib','style_contrib'};
            FieldToAvg = {'nsec','TC','activeness','facwgt','factorExp','alphaScore','totalbmwgt','netactwgt','style_netwgt','style_grswgt','variance'};
        case 'unireg'
            FieldToSum = {'actRtn','fwdret_dm','StockRet_Alpha','StockRet_Spec','stock_contrib','alpha_contrib','factor_contrib','spec_contrib','style_contrib'};
            FieldToAvg = {'nsec','TC','activeness','bmhd','actwgt','factorScore','facwgt','alphaScore','factorScore','totalbmwgt','netactwgt','style_netwgt','style_grswgt','style_exp','variance'};
    end
    
end


StartDate = datenum(StartDate);
EndDate = datenum(EndDate);

dates = TSResult.actRtn.dates;
StartDate = dates(find(dates <= StartDate,1,'last'));
EndDate = dates(find(dates <= EndDate,1,'last'));
PerIdx = dates >= StartDate & dates <= EndDate;

% Get the start and enddate of this calculation
Result.start = datestr(StartDate, 'yyyy-mm-dd');
Result.end = datestr(EndDate, 'yyyy-mm-dd');

% calculate value for fields that should be summed
for i = 1:numel(FieldToSum)
    Result.(FieldToSum{i}) = nansum(TSResult.(FieldToSum{i})(PerIdx,:),1);
end

% calculate value for fields that should be averaged
for j = 1:numel(FieldToAvg)
    if strcmpi(FieldToAvg{j}, 'factorScore')
        Result.(FieldToAvg{j}) = nanmean(TSResult.(FieldToAvg{j})(PerIdx,:,:),1);
    elseif strcmpi(FieldToAvg{j}, 'variance')
        Result.(FieldToAvg{j}) = TSResult.(FieldToAvg{j});
    else
        Result.(FieldToAvg{j}) = nanmean(TSResult.(FieldToAvg{j})(PerIdx,:),1);
    end
end

% calculate value for other fields 
Result.actRisk = nanstd(TSResult.actRtn(PerIdx,:))*sqrt(252);
Result.IR = nanmean(TSResult.actRtn(PerIdx,:))*252./Result.actRisk;

% calculate statistics of stocks that contribute most to the active performance
stock_contrib = nansum(TSResult.stock_contrib(PerIdx,:));
botidx = RankArray_V2(stock_contrib,2,'ascend') <= 10;
topidx = RankArray_V2(stock_contrib,2,'descend') <= 10;

alphaScore = nanmean(TSResult.alphaScore(PerIdx,:));
actwgt = nanmean(TSResult.actwgt(PerIdx,:));
secid = fieldnames(TSResult.actwgt,1);
secid = cellfun(@(x){x(5:end)}, secid);

switch lower(method)
    case 'signalpf' % in the case of signal portfolio based approach
        stock_alpha_contrib = nansum(TSResult.stock_alpha_contrib(PerIdx,:));
        stock_constr_contrib = nansum(TSResult.stock_constr_contrib(PerIdx,:));
        alphawgt = nanmean(TSResult.alphawgt(PerIdx,:));
        constr_wgt = nanmean(TSResult.constr_wgt(PerIdx,:));
        stock_alpha_contrib(isnan(stock_alpha_contrib)) = 0;
        stock_constr_contrib(isnan(stock_constr_contrib)) = 0;

        Result.bot.secid = secid(botidx);
        Result.bot.contrib = stock_contrib(botidx);
        Result.bot.actwgt = actwgt(botidx);
        Result.bot.alpha = alphaScore(botidx);
        Result.bot.alpha_contrib = stock_alpha_contrib(botidx);
        Result.bot.alphawgt = alphawgt(botidx);
        Result.bot.constr_contrib = stock_constr_contrib(botidx);
        Result.bot.constr_wgt = constr_wgt(botidx);
    case 'unireg' % in the case of univariate regression based approach
        StockRet_Alpha = nansum(TSResult.StockRet_Alpha(PerIdx,:));
        StockRet_Spec = nansum(TSResult.StockRet_Spec(PerIdx,:));
        fwdret_dm = nansum(TSResult.fwdret_dm(PerIdx,:));
        
        Result.bot.secid = secid(botidx);
        Result.bot.alpha = alphaScore(botidx);
        Result.bot.contrib = stock_contrib(botidx);
        Result.bot.fwdret_dm = fwdret_dm(botidx);
        Result.bot.actwgt = actwgt(botidx);
        Result.bot.StockRet_Alpha = StockRet_Alpha(botidx);
        Result.bot.StockRet_Spec = StockRet_Spec(botidx);
        
        Result.top.secid = secid(topidx);
        Result.top.alpha = alphaScore(topidx);
        Result.top.contrib = stock_contrib(topidx);
        Result.top.fwdret_dm = fwdret_dm(topidx);
        Result.top.actwgt = actwgt(topidx);
        Result.top.StockRet_Alpha = StockRet_Alpha(topidx);
        Result.top.StockRet_Spec = StockRet_Spec(topidx);        
    otherwise
        error('invalid attribution method input');
end


return
