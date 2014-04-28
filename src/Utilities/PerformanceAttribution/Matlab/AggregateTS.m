function TS = AggregateTS(Result, isstgylevel, method)
% this function aggregate the Time Series Result from lower level to upper
% level (submodel to model, or model to strategy)

switch lower(method)
    case 'signalpf'
        FieldToAppend = {'bmhd','actwgt','alphaScore','stock_contrib','stock_constr_contrib','stock_alpha_contrib','constr_wgt','alphawgt'};
        FieldToSum = {'nsec','totalbmwgt','netactwgt','error_contrib','activeness','actRtn','alphaCappedRtn','alpha_contrib','constraint_contrib','style_contrib'};
    case 'unireg'
        FieldToAppend = {'bmhd','actwgt','alphaScore','stock_contrib','StockRet_Alpha','StockRet_Spec','fwdret_dm'};
        FieldToSum = {'nsec','totalbmwgt','netactwgt','activeness','actRtn','alpha_contrib','spec_contrib','style_contrib','style_exp'};
    otherwise
        error('invalid attribution method!');
end


for i = 1:numel(Result)
    if isempty(Result{i})
        continue;
    end
    if i == 1
        for j = 1:numel(FieldToAppend)
            TS.(FieldToAppend{j}) = Result{i}.TS.(FieldToAppend{j});
        end
        for j = 1:numel(FieldToSum)
            TS.(FieldToSum{j}) = Result{i}.TS.(FieldToSum{j});
        end
        % special treatment for style weight
        TS.style_netwgt = bsxfun(@times, Result{i}.TS.style_netwgt, Result{i}.TS.activeness);
        TS.style_grswgt = bsxfun(@times, Result{i}.TS.style_grswgt, Result{i}.TS.activeness);
    else
        for j = 1:numel(FieldToAppend)
            TS.(FieldToAppend{j}) = [TS.(FieldToAppend{j}), Result{i}.TS.(FieldToAppend{j})];
        end
        for j = 1:numel(FieldToSum)
            TS.(FieldToSum{j}) = bsxfun(@plus, TS.(FieldToSum{j}), Result{i}.TS.(FieldToSum{j}));
        end
        % special treatment for style weight
        TS.style_netwgt = bsxfun(@plus, TS.style_netwgt, bsxfun(@times, Result{i}.TS.style_netwgt, Result{i}.TS.activeness));
        TS.style_grswgt = bsxfun(@plus, TS.style_grswgt, bsxfun(@times, Result{i}.TS.style_grswgt, Result{i}.TS.activeness));
    end
end

% sepcial treatment for style weight
TS.style_netwgt = bsxfun(@rdivide, TS.style_netwgt, TS.activeness);
TS.style_grswgt = bsxfun(@rdivide, TS.style_grswgt, TS.activeness);


if isstgylevel == 1
    TS.totalbmwgt(:,:) = 1.00;
    TS.netactwgt(:,:) = 0.00;
end

% special treatment for TC
TS.TC = cscorr(TS.actwgt, TS.alphaScore, 'rows', 'complete');

end