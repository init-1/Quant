% This function combines the individual asset constraint to the final lower
% bound, upper bound of position, and maximum trade size of buy / sell

function [weightcons, sharecons, actsharecons] = RefineAssetConstraint(assetcons)

weightcons = struct('ub',[],'lb',[],'buy',[],'sell',[]);
sharecons = struct('ub',[],'lb',[],'buy',[],'sell',[]);
actsharecons = struct('ub',[],'lb',[]);

for j = 1:numel(assetcons)
    if strcmpi(assetcons{j}.type, 'position')
        switch assetcons{j}.unit
            case 'weight'
                lb = weightcons.lb;
                ub = weightcons.ub;
            case 'share'
                lb = sharecons.lb;
                ub = sharecons.ub;
        end
        if isempty(lb)
            lb = assetcons{j}.lb;
        end
        if isempty(ub)
            ub = assetcons{j}.ub;
        end
        lb = max(lb, assetcons{j}.lb); % common lower bound is the maximum of all lower bound
        ub = min(ub, assetcons{j}.ub); % common upper bound is the minimum of all upper bound
        switch assetcons{j}.unit
            case 'weight'
                weightcons.lb = lb;
                weightcons.ub = ub;
            case 'share'
                sharecons.lb = lb;
                sharecons.ub = ub;
        end
    end
    
    if strcmpi(assetcons{j}.type, 'trade')
        switch assetcons{j}.unit
            case 'weight'
                sell = weightcons.sell;
                buy = weightcons.buy;
            case 'share'
                sell = sharecons.sell;
                buy = sharecons.buy;
        end
        if isempty(buy)
            buy = assetcons{j}.ub;
        end
        if isempty(sell)
            sell = assetcons{j}.lb;
        end
        buy = min(buy, assetcons{j}.ub); % common buy size is the minimum of all buy size
        sell = min(sell, assetcons{j}.lb); % common sell size is the minimum of all sell size
        switch assetcons{j}.unit
            case 'weight'
                weightcons.sell = sell;
                weightcons.buy = buy;
            case 'share'
                sharecons.sell = sell;
                sharecons.buy = buy;
        end
    end
    
    if strcmpi(assetcons{j}.type, 'actposition')
        switch assetcons{j}.unit
            case 'share'
                lb = actsharecons.lb;
                ub = actsharecons.ub;
        end
        if isempty(lb)
            lb = assetcons{j}.lb;
        end
        if isempty(ub)
            ub = assetcons{j}.ub;
        end
        lb = max(lb, assetcons{j}.lb); % common lower bound is the maximum of all lower bound
        ub = min(ub, assetcons{j}.ub); % common upper bound is the minimum of all upper bound
        switch assetcons{j}.unit
            case 'share'
                actsharecons.lb = lb;
                actsharecons.ub = ub;
        end
    end
end

return