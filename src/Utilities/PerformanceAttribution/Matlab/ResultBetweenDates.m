function StrategyResult = ResultBetweenDates(StrategyResult, rptStart, rptEnd, FieldName, method)

actwgt = StrategyResult.TS.actwgt;
PFBeginDate = actwgt.dates(find(any(~isnan(fts2mat(actwgt)),2),1,'first'));
rptStart = max(PFBeginDate, datenum(rptStart));
rptEnd = datenum(rptEnd);
switch lower(method) % define the fields to calculate on model/strategy level
    case 'signalpf'
        FieldToSum = {'actRtn','alpha_contrib','alphaCappedRtn','constraint_contrib','error_contrib','style_contrib','stock_constr_contrib','stock_alpha_contrib'};
        FieldToAvg = {'nsec','TC','activeness','totalbmwgt','netactwgt','style_netwgt','style_grswgt','variance'};
    case 'unireg'
        FieldToSum = {'actRtn','alpha_contrib','spec_contrib','fwdret_dm','style_contrib'};
        FieldToAvg = {'nsec','TC','activeness','totalbmwgt','netactwgt','style_netwgt','style_grswgt','style_exp','variance'};        
    otherwise
        error('invalid attribution method!');
end

modellist = StrategyResult.modellist;
ModelResult = StrategyResult.ModelResult;
for j = 1:numel(modellist.modelid)
    SubModelResult = ModelResult{j}.SubModelResult;
    num_submodel = numel(SubModelResult);
    for m = 1:num_submodel
        if ~isempty(SubModelResult{m})
            SubModelResult{m}.(FieldName) = CalcPeriodToDateResult(SubModelResult{m}.TS, rptStart, rptEnd, method);
        end
    end
    ModelResult{j}.SubModelResult = SubModelResult;
    ModelResult{j}.(FieldName) = CalcPeriodToDateResult(ModelResult{j}.TS, rptStart, rptEnd, method, FieldToSum, FieldToAvg);
end

StrategyResult.ModelResult = ModelResult;
StrategyResult.(FieldName) = CalcPeriodToDateResult(StrategyResult.TS, rptStart, rptEnd, method, FieldToSum, FieldToAvg);

end