function score = normalize(factor, varargin)
    option.mode = 'ascend';
    option.method = 'zscore';
    option.GICS = [];
    option.weight = [];
    option.level = 1;
    option = Option.vararginOption(option, fieldnames(option), varargin{:});

    % Check if input data are aligned
    for ftsField = {'weight', 'GICS'}
        ftsname = ftsField{:};
        if isa(option.(ftsname), 'myfints')
           FTSASSERT(isaligneddata(factor, option.(ftsname)), '%s and factor are not aligned', ftsname);
           option.(ftsname) = fts2mat(option.(ftsname));
        end
    end
    
    % NEED to differentiate two kinds of NaNs: 
    %   1. NaN since missing value
    %   2. NaN since it's not belonging to the universe or sector (in
    %   neutralize(), all NaN will be treated as this way)
    %
    % First, set all NaNs as Inf to indicate it may be missing values
    s.type = '()'; s.subs = {isnan(fts2mat(factor))};
    factor = subsasgn(factor, s, inf);  % equiv. factor(isnan(fts2mat(factor))) = inf;
    %
    % Then set those not in universe to NaNs
    if ~isempty(option.weight)
        s.type = '()'; s.subs = {option.weight == 0 | isnan(option.weight)};
        factor = subsasgn(factor, s, NaN);  % factor(option.weight == 0 | isnan(option.weight)) = NaN;
    end
    %
    % And remember if neutralize, neutralize() will set those not in the sector considered into NaNs.
    % Thus, we actually use Inf to indicate missing values, NaN non-universe/non-sector values
    % So normalization function should take into Inf approriately.

    fun = [];
    if strcmpi(option.method, 'norminv')
        fun = @(x) norminv(x, option.mode);
    elseif strcmpi(option.method, 'zscore')
        fun = @zscore;
    elseif strcmpi(option.method, 'rank')
        fun = @(x) rankArray(x, 2, option.mode);
    elseif strncmpi(option.method, 'cumbucket', length('cumbucket'))
        nBucket = str2double(option.method(length('cumbucket')+1:end));
        fun = @(x) cumbucktize(x, nBucket, option.mode);
        elseif strncmpi(option.method, 'rankbucket', length('rankbucket'))
        nBucket = str2double(option.method(length('rankbucket')+1:end));
        fun = @(x) rankbucktize(x, nBucket, option.mode);
    end

    FTSASSERT(~isempty(fun), 'Unrecognized nomalization methods: %s', option.method);
    score = neutralize(factor, option.GICS, fun, option.level);
end

% function a = norminv(a, mode)
%     for t = 1:size(a,1)
%         % Step 0: remove noninvolved data
%         a_ = a(t,:);
%         incidx = ~isnan(a_);
%         a_ = a_(incidx);
%         
%         % Step 1: Ranking
%         a_(isinf(a_)) = nan;
%         a_ = rankArray(a_, 2, mode);
%         nanIdx = isnan(a_);
%         numNonNaN = sum(~nanIdx, 2);
%         numTotal = size(a_, 2);
%         nanRank = repmat(0.55 * (numNonNaN+1), 1, numTotal);
%         a_(nanIdx) = nanRank(nanIdx);
%         a_ = rankArray(a_, 2, 'ascend');
%         nanRank = repmat(floor(0.55 * (numTotal+1)), size(a_));
%         a_(nanIdx) = nanRank(nanIdx);
%         FTSASSERT(sum(sum(isnan(a_))) == 0, 'Rankings contain NaNs');
% 
%         % Step 2: Calculating Score
%         a_ = bsxfun(@rdivide, a_, numTotal+1);
% 
%         % Step 3: Calculating normalized score
%         a_ = (1-2*a_) ./ ((abs(1-0.985*abs(1-2*a_))) .^ 0.25);
%         upperBound = max(a_,[],2);
%         if upperBound == 0
%             a_ = 0.5*ones(size(a_));
%         else
%             a_ = 0.5 - bsxfun(@rdivide, a_, upperBound.*2) .* (numTotal-2)./numTotal;  %% what if numTotal < 2?
%         end
%         
%         % Finally set back to a
%         a(t,incidx) = a_;
%     end
%     a = a - 0.5;
% end

function a = norminv(a, mode)
    for t = 1:size(a,1)
        % Step 0: remove noninvolved data
        a_ = a(t,:);
        incidx = ~isnan(a_);
        a_ = a_(incidx);
        
        % Step 1: Ranking
        a_(isinf(a_)) = nan;
        noNaNidx = ~isnan(a_);
        a_noNaN = a_(noNaNidx);
        raw_noNaN = a_noNaN;
        a_noNaN = rankArray_v3(a_noNaN, 2, mode);
        numnoNaN = numel(unique(a_noNaN));
        
        % Step 2: Calculating Score
        if numnoNaN == 1
            a_noNaN = 0.5;
        elseif numnoNaN > 1
            a_noNaN = bsxfun(@rdivide, a_noNaN, numnoNaN+1);
            % Step 3: Calculating normalized score
            a_noNaN = (1-2*a_noNaN) ./ ((abs(1-0.985*abs(1-2*a_noNaN))) .^ 0.25);
            upperBound = max(abs(a_noNaN),[],2);
            if upperBound == 0
                a_noNaN = 0.5*ones(size(a_noNaN));
            else
                a_noNaN = 0.5 - bsxfun(@rdivide, a_noNaN, upperBound.*2) .* (numnoNaN-2)./numnoNaN;  %% what if numTotal < 2?
            end
            
            % Step 4: Set the mean of norm values to all the same raw scores
            a_noNaN = refineNormScore(a_noNaN,raw_noNaN);            
        end         
        
        % set back to a_
        a_(noNaNidx) = a_noNaN;
        a_(~noNaNidx) = 0.5; 
        
        % Finally set back to a
        a(t,incidx) = a_;
    end
    a = a - 0.5;
    
end

function refineScore = refineNormScore(normScore,rawScore)
%This function is meant to set the same value to normalized score 
%if it has same raw factor value. The new value is set to be equal 
%to mean of the norm scores.

    refineScore = nan(size(normScore));
    distinctScore = unique(rawScore);
    for i=1:numel(distinctScore)
        idx = rawScore == distinctScore(i);
        refineScore(idx) = mean(normScore(idx));
    end
end

function a = zscore(a)
    missingValuesIdx = isinf(a);
    a(missingValuesIdx) = NaN;
    mu = nanmean(a, 2); 
    sigma = nanstd(a, 0, 2);
    a = bsxfun(@rdivide, bsxfun(@minus, a, mu), sigma);
    a(missingValuesIdx) = 0;  % set a middle value
    a(a >  3) = 3;
    a(a < -3) = -3;
end

function rank = rankArray(toBeRanked, dim, mode)
% note NaNs be treated as maximum in matlab sorting, even greater than inf
    toBeRanked(isinf(toBeRanked)) = NaN; %%% We don't consider inf currently
    [~,idx] = sort(toBeRanked, dim, mode);
    [~,rank] = sort(idx, dim, 'ascend');
    numNaN = sum(isnan(toBeRanked), dim);
    if strcmpi(mode, 'descend')
        rank = bsxfun(@minus, rank, numNaN); % make rank of non-NaNs counted from 1
    end
    rank(rank <= 0 | bsxfun(@gt, rank, size(toBeRanked,2)-numNaN)) = nan;
end

function finalRank = rankArray_v2(toBeRanked, dim, mode)
% note NaNs be treated as maximum in matlab sorting, even greater than inf
    toBeRanked(isinf(toBeRanked)) = NaN; %%% We don't consider inf currently
    nanidx = isnan(toBeRanked);
    distinctVal = (toBeRanked(~nanidx));
    
    [~,idx] = sort(distinctVal, dim, mode);
    [~,rank] = sort(idx, dim, 'ascend');
    
    finalRank = nan(size(toBeRanked));
    for i = 1:numel(distinctVal)
        rank_selected=rank(toBeRanked == distinctVal(i));
        finalRank(toBeRanked == distinctVal(i)) = mean(rank_selected);
    end
end

function finalRank = rankArray_v3(toBeRanked, dim, mode)
    toBeRanked(isinf(toBeRanked)) = NaN; %%% We don't consider inf currently
    nanidx = isnan(toBeRanked);
    distinctVal = (toBeRanked(~nanidx));    
    
    finalRank = nan(size(toBeRanked));
    [~,idx] = sort(distinctVal, dim, mode);
    [~,rank] = sort(idx, dim, 'ascend');            
    finalRank(~nanidx) = rank;
end

function bk = rankbucktize(a, nBucket, mode)
    a(isinf(a)) = NaN;
    dim = 2;
    rank = rankArray(a, dim, mode);
    bk = NaN(size(a));
    threshold = prctile(rank, 0:100/nBucket:100, dim);
    for i = 1:nBucket
        bk(bsxfun(@ge,rank,threshold(:,i)) & bsxfun(@le,rank,threshold(:,i+1))) = i;
    end
end

function a = cumbucktize(a, nBucket, mode)
    epsilon = 1e-6;
    a(isinf(a)) = NaN;
    % since cumsum don't consider nans, we use a loop for now
    for t = 1:size(a,1)
        a_ = a(t,:);
        incidx = ~isnan(a_);
        a_ = a_(incidx);
        [a_, ix] = sort(a_, mode);
        a_ = a_ ./ sum(a_);
        cum = cumsum(a_);
        bk = NaN(size(a_));
        threshold = 0:1/nBucket:1;
        threshold(end) = threshold(end)+epsilon;
        for i = 1:nBucket
            bk(cum >= threshold(i) & cum < threshold(i+1)) = i;
        end
        a_(ix) = bk;
        a(t, incidx) = a_;
    end
end