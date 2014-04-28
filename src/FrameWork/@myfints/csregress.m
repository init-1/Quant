function [beta, epsilon, std_b, R2, mse, yhat, adjR2, R2contrib, facPF] = csregress(ret, factors, varargin)
    option.weight = [];
    option = Option.vararginOption(option, {'weight'}, varargin{:});

    if isa(option.weight, 'myfints')
        FTSASSERT(isaligneddata(ret, option.weight), 'ret and weight not aligned');
        option.weight = fts2mat(option.weight);
        option.weight(isnan(option.weight)) = 0;
    end
    FTSASSERT(isaligneddata(ret, factors{:}), 'ret and factors not aligned');
    
    retData = fts2mat(ret);
    [T, N] = size(retData);   % T: num of obversations; N: number of 
    K = length(factors);
    if isempty(option.weight)
        option.weight = ones(T,N);
    end
    facData = NaN(K, N, T);
    for k = 1:K
        facData(k,:,:) = (fts2mat(factors{k}))';
    end
    date = ret.dates;

    b = NaN(T, K);
    std_b = NaN(T, K);
    mse = NaN(T, 1);
    e = NaN(T, N);
    R2 = NaN(T,1);
    R2contrib = NaN(T,K);
    adjR2 = NaN(T,1);
    yhat = NaN(T, N);
    facPF = cell(1,K);
    for k = 1:K
        facPF{k} = NaN(T, N);
    end
    p = K-1; % NO. of regressors, assuming first factor is constant
    for t = 1:T
        %  Regression of y_t against x_t
        picked = option.weight(t,:)>0 & ~isnan(retData(t,:)) & ~isnan(sum(facData(:,:,t),1));
        % FTSASSERT(sum(picked) > 0, 'Oops... There''s no stocks be selected on %s. Check your data.', datestr(date(t)));
        if sum(picked) == 0
            disp(['warning: There''s no stocks be selected on %s. Check your data.', datestr(date(t))]);
            continue;
        end
        y = retData(t,picked)';
        X = facData(:,picked,t)';
%        xidx = ~all(X==0,1);
        xidx = CleanLinearDependence(X);
        w = option.weight(t,picked)';
        if nansum(xidx) > 0
            [b(t,xidx), std_b(t,xidx), mse(t,:)] = lscov(X(:,xidx), y, w);
        end
        b(t,~xidx) = 0;
        residual = y - X * b(t,:)';
        yhat(t,picked) = X * b(t,:)';
        y_ = y - mean(y);
        R2(t) = 1 - residual' * residual / (y_' * y_);
        for k = 1:K
            Xb = X(:,k) * b(t,k) - mean(X(:,k) * b(t,k));
            R2contrib(t,k) = (y_' * Xb) / (y_' * y_);
        end
        adjR2(t) = 1-(1-R2(t))*(numel(y)-1)/(numel(y)-p-1);
        e(t,picked) = residual;
        % get factor portfolio (with unit 1 exposure to itself, and 0 exposure to other factors
        tempFacPF = NaN(K,sum(picked));
        tempFacPF(xidx,:) = (X(:,xidx)'*diag(w)*X(:,xidx))\(X(:,xidx)'*diag(w)); % left division - equivalent to inv(X'*diag(w)*X)*(X'*diag(w)) 
        
        for k = 1:K
            facPF{k}(t,picked) = tempFacPF(k,:);
        end
    end
    
    sids = fieldnames(ret,1);
    freq = ret.freq;
    fids  = cell(K,1);
    fids(1:K) = mat2cell(strcat('F', num2str((1:K)')), ones(K,1));
    fids  = regexprep(fids, '\s', '0');
    for i = 1:K
        fname = class(factors{i});
        if ~strcmp(fname, 'myfints')
            fids{i} = fname;
        end
    end

    beta = myfints(date, b, fids, freq, 'Regress Beta');
    epsilon = myfints(date, e, sids, freq, 'Regress Residual');
    std_b = myfints(date, std_b, fids, freq, 'Regress Std Beta');
    R2 = myfints(date, R2, 'R2', freq, 'Regress R-Squared');
    R2contrib = myfints(date, R2contrib, fids, freq, 'R-Squared Contribution');
    adjR2 = myfints(date, adjR2, 'adjR2', freq, 'Adjusted R-Squared');
    mse   = myfints(date, mse, 'MSE', freq, 'Regress MSE');
    yhat = myfints(date, yhat, sids, freq, 'Expected Value of Dependent Variable');
    for k = 1:K
        facPF{k} = myfints(date, facPF{k}, sids, freq, 'Pure Factor Portfolio');
    end
end

function xidx = CleanLinearDependence(X)
    % this function finds the possible linearly dependent columns in a matrix,
    % clean it until it's not rank deficient, and return the index of cleaned matrix 

    xidx = ~all(X==0,1); % get rid of any all-zero columns
    OneOrZero = sum(ismember(X,[1,0]),1);
    dummyidx = find(OneOrZero == size(X,1) & xidx); % find those columns which only contain 1 or 0
    if isempty(dummyidx)
        return;
    end
    tmpRank = rank(X(:,xidx));    
    if tmpRank < sum(xidx) % if it is rank deficient
        for i = 1:numel(dummyidx)
            xidx(dummyidx(i)) = false; % exclude one of the dummy variable
            if rank(X(:,xidx)) < tmpRank % check whether rank decreases becoz of the excluding
                xidx(dummyidx(i)) = true; % if yes, then should not exclude
            elseif rank(X(:,xidx)) == sum(xidx) % if no, check whether it is still rank deficient
                break; % if not rank deficient any more, break the loop
            else
                tmpRank = rank(X(:,xidx)); % if still rank deficient, update tmpRank, go for next dummyidx
            end
        end
    end
end
