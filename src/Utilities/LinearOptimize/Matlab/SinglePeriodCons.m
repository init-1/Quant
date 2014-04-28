% this function construct single period constraints from the input
% multi-period constraints. It converts weight/share based trading/holding
% constraints to standard weight holding constraints

function [tempub, templb, tempcons] = SinglePeriodCons(i, inihd, price, pfvalue, bmhd, weightcons, sharecons, actsharecons, attributecons)
    
%% set asset cons for one period

% weight based constraints
if ~isempty(weightcons.ub) 
    tempub = weightcons.ub(i,:);
    templb = weightcons.lb(i,:);
end
if ~isempty(weightcons.buy) && i > 1 % trading contraint only applies after 1st period
    buyweight = sharecons.buy(i,:);
    sellweight = sharecons.sell(i,:);
    tempub = min(tempub, inihd(i,:) + buyweight);
    templb = max(templb, inihd(i,:) - sellweight);
end

% share based constraints
if ~isempty(sharecons.ub) 
    ubweight = sharecons.ub(i,:).*price(i,:)/pfvalue(i);
    lbweight = sharecons.lb(i,:).*price(i,:)/pfvalue(i);
    tempub = min(tempub, ubweight);
    templb = max(templb, lbweight);
end
if ~isempty(sharecons.buy) && i > 1 % trading contraint only applies after 1st period
    buyweight = sharecons.buy(i,:).*price(i,:)/pfvalue(i);
    sellweight = sharecons.sell(i,:).*price(i,:)/pfvalue(i);
    tempub = min(tempub, inihd(i,:) + buyweight);
    templb = max(templb, inihd(i,:) - sellweight);
end

% active share based constraints
if ~isempty(actsharecons.ub) 
    ubweight = bmhd(i,:) + actsharecons.ub(i,:).*price(i,:)/pfvalue(i);
    lbweight = bmhd(i,:) - actsharecons.lb(i,:).*price(i,:)/pfvalue(i);
    tempub = min(tempub, ubweight);
    templb = max(templb, lbweight);
end


%% set attribute cons for one period
tempcons = attributecons;
for j = 1:numel(attributecons)
    tempcons{j}.A = attributecons{j}.A(i,:);
    if numel(attributecons{j}.b) > 1
        tempcons{j}.b = attributecons{j}.b(i);
    end
end

return