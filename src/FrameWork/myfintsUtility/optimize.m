function [W, IR_optm, alpha, IC, exitflag, latter_optm, conVal] = optimize(factors, stockRet, bmhd, varargin)
% stockRet is forward return
% OPTIMIZE tries to obtain optimal weights (by maximizing IR) for multiple 
% alpha sources (factors) based on their historical performance (in terms of IC).
%
% Syntax:
%  [W,IR_optm,alpha,IC,exitflag] = OptimalWeights(fe,stock,vdates,'parameter',value,...)
%
% Inputs:
%
%    factors  : A cell vector of myfints objs containing factors
%    stockRet : A myfints obj representing securities returns
%   'parameter',value,... : pairs acting as named arguments providing additional 
%          information to the optimization process. Possible parameters are
%      method : Default 'M/V:RHO'.
%         lag : how many lagged factors be involved 
%               (current factor value always be included and not counted in).
%               value should be >=0, integer, default is 11.
%         rho : constraint on first-order autocorrelation of the blended factor, 
%               should be in [0,1], default is 0.95.
%       ICWin : [numPast, numForward]. 
%               numPast == 0 or Inf means EXPANDING window, others the actual windows size; 
%               should at least lag+2, integer, default is 36. 
%               numForward == Inf means include all future periods in the sample.
%               Default is 0
%       lambda : control weight mass distribution among weights, should > 0, default 0.
%       facgroup: factor groups (e.g. styles or other customized group) 
%
% Outputs:
%    W  : optimal weights, T x K(L+1) where T is number of period in {vdates}, 
%         K the number of factors and L is the number of lags involved. 
%         Each \emph{row} corresponding to a time period in {vdates} and
%         in form of (
%            w(1,t), w(1,t-1), ..., w(1, t-lag1),
%            w(2,t), w(2,t-1), ..., w(2, t-lag2),
%            ..., 
%            w(K,t), w(K,t-l), ..., w(K, t-lagK)
%         )
%         where $w_{k,t}$ indicates optimal weight for k-th factor at time t.
%  IR_optm : the IR values when the W is applied to the objective function, T x 1.
%  alpha   : the alphas when apply W to blend factors, T x N where N is the number of stocks.
%  IC      : information coefficients for each factor (include lagged factors) 
%            at every time period, T x K(L+1).
%  exitflag: flags for diagnosing optimization process. 1 indicates success, 
%            0 not convergent, negative values indicate problems. 
%            See also fmincon. T x 1, each element for one period optimization.
%
% Note that T in outputs part is corresponding to {vdates}. 
% All matrices and vector returned have the same number of rows (T).
% The very first few rows (for no enough lagged factors}) may be {NaN}s.

%%--------------------------- Check Data Arguments ------------------------------
FTSASSERT(isaligneddata(factors{:},stockRet,bmhd), 'Factors , Stock Return , holdings objs are not aligned');
numFactor = length(factors);
[numDate,numStock] = size(stockRet);

%%--------------------------- Process options ------------------------------
% options serveing our purpose. All numerical options should be >= 0; ICWindow and ICFwdWin can be Inf.
% make sure ICWindow > lag+2, exact relatipnship depends on time stamp of data and vdates
myoption.lag = 0;       % how many lagged factors be involved
myoption.rho = 0.85;     % constriaint on first-order autocorrelation of blended factor
myoption.initVal = 'EW'; % could be 'EW', 'RAND', 'B<number>' where <number> indicates posn of weight initialized as 1 (others are zeros)
myoption.lambda = 0;     % control mass distribution among weights
myoption.method = 'M/V:RHO'; % can be 'M/V' or 'M-V'
myoption.lb = 0;         % lower bounds for weights. 
myoption.ub = 1;         % upper bounds for weights
myoption.IC = [];        % IC provided by user instead of calculating by this function; [] means user does not provided IC
myoption.ICWin = [36 0]; % first for num of past periods included in the IC calculation win , second for future periods.
                         % for fitst, 0 or Inf means EXPANDING window, others the ACTUAl windows size; should > lag+2
                         % for second, 0 indicates NO forward-looking, Inf looking all forward periods in the samle
myoption.ICStopLossWin = 0;
myoption.ICMeanFun = @nanmean;
myoption.ICCovFun = @nancov;
myoption.facgroup = [1:numel(factors)];

% overwritting options with values provided by callers
myoption = Option.vararginOption(myoption, fieldnames(myoption), varargin{:});

if isequal(size(myoption.ICWin), [1 2])
    myoption.ICWin = [myoption.ICWin; myoption.ICWin];  % first row for mean(IC), 2nd for std(IC)
end
if myoption.ICWin(1,1) == 0, myoption.ICWin(1,1) = Inf; end
if myoption.ICWin(2,1) == 0, myoption.ICWin(2,1) = Inf; end

[objStr, conStr] = strtok(upper(myoption.method), ':');
if isempty(conStr)
    con = [];
else 
    conStr(1) = [];   % remove leading ':'
    switch conStr
        case 'RHO_EQ'
            con = @RHO_eq;
        case 'RA_EQ'
            con = @RHO_diffw_eq;
        case 'RFAC_EQ'
            con = @RHO_factor_eq;
        case 'RHO'
            con = @RHO;
        case 'RA'
            con = @RHO_diffw;
        case 'RFAC'
            con = @RHO_factor;            
        otherwise
            FTSASSERT(false, 'Unrecognized blending/optimization methods');
    end
end
switch objStr
    case 'EW'
        obj = []; con = [];
    case 'M/V'
        obj = @IR_w;
    case 'M-V'
        obj = @IR_w_variant;
    case 'DIFW'
        obj = @IR_diffw; con = [];
    case 'RISKPAR'
        obj = 'RISKPAR'; con = [];
    case 'RISKPAR-GRP'
        obj = 'RISKPAR-GRP'; con = [];
    otherwise
        FTSASSERT(false, 'Unrecognized blending/optimization methods');
end

% check option.lag and expand it to match number of factors if necessary
if length(myoption.lag) == 1
    myoption.lag = ones(numFactor,1) .* myoption.lag;
end
FTSASSERT(numFactor == length(myoption.lag));
numCMAFactor = sum(myoption.lag+1);

% generate initial weights W0
switch myoption.initVal
    case 'EW'   % equally-weighted
        w0 = ones(numCMAFactor, 1) * 1/numCMAFactor;
    case 'RAND' % random
        w0 = rand(numCMAFactor, 1);
        w0 = w0 ./ sum(w0);
    otherwise
        OK = false;
        if myoption.initVal(1) == 'B'
            posn = str2double(myoption.initVal(2:end));
            if ~isempty(posn)
               w0 = zeros(numCMAFactor, 1);
               w0(posn) = 1;
               OK = true;
            end
        end
        if ~OK, error('Invalid init weights specified!'); end
end

%% options for optimization function
optimoption.Algorithm = 'interior-point';
optimoption.LargeScale = 'on';
optimoption.DerivativeCheck = 'off';
optimoption.Diagnostics = 'off';
optimoption.GradConstr = 'on';    %%%% change back later
optimoption.GradObj = 'on';
optimoption.FinDiffType = 'Central';
optimoption.Display = 'off';   %% 'iter'
optimoption.MaxIter = 1500;
optimoption.MaxFunEvals = 5000;

% Set optimization options
optargs = Option.stackOption(optimoption);
optimoption = optimset(optargs{:}); % old optimoption gone

%% Prepare and rearrange data
% Pooled Factors
F = NaN(numCMAFactor, numStock, numDate); 
F_prev = NaN(numCMAFactor, numStock, numDate);
F_fts = cell(numCMAFactor,1);
i = 0;
for f = 1:numFactor
    for lag = 0:myoption.lag(f)   % include one more lag to facilitae calc of D below
        i = i+1;
        tmplagfts = lagts(factors{f},lag);
        if lag > 0
            tmplagfts(isnan(fts2mat(tmplagfts)) & ~isnan(fts2mat(bmhd))) = 0;
        end
        F(i,:,:) = fts2mat(tmplagfts)';
        F_prev(i,:,:) = fts2mat(lagts(tmplagfts,1))';
        F_fts{i} = tmplagfts;
    end
end

if isempty(myoption.IC)           
    IC = NaN(numDate, numCMAFactor);
    r = fts2mat(stockRet);
    for t = 1:numDate;
        IC(t,:) = corr(r(t,:)', F(:,:,t)', 'type', 'Spearman', 'rows', 'pairwise');
    end
else
    FTSASSERT(isidenticaldates(myoption.IC, stockRet) && size(myoption.IC,2) == numCMAFactor);
    IC = fts2mat(myoption.IC);
end

if strcmpi(objStr,'riskpar') || strcmpi(objStr,'riskpar-grp')       
    F_facRtn = myfints(stockRet.dates, nan(numDate, numCMAFactor));
    %Calculate the factorPF return,Autocorrelation, and covariance matrix here    
    for i = 1:numCMAFactor
        F_facRtn(:,i) = fts2mat(factorPFRtn(F_fts{i},stockRet,bmhd));
    end
    F_lagfacRtn = lagts(F_facRtn,1,nan);    
    F_lagfacRtn(isinf(F_lagfacRtn)) = NaN; % !! don't set NaN value to be zero, otherwise it will mess up the covariance calculation
    covRtn = nan(numDate,numCMAFactor,numCMAFactor);
    AC = cell(numCMAFactor,1);
    for j = 1:numCMAFactor
        AC{j} = csrankcorr(F_fts{j}, lagts(F_fts{j},1,nan));
    end       
    % minimum periods reserved to facilitate covariance matrix calculation
    % atleast 60 months
    winsize = myoption.ICWin(2,1);
    startidx = min(60,min(winsize,numDate)); 
    
    for i = startidx:numDate                
        if isinf(winsize)
            s = 1; %Expanding            
        else
            s = max(i-winsize+1,1); %Rolling
        end           
        tmp = F_lagfacRtn(s:i,:);
        tmp(:,sum(isnan(fts2mat(tmp)),1)./size(fts2mat(tmp),1) > 0.6) = NaN; % if more than 60% of the column is NaN, set that column to be all NaN
        c = myoption.ICCovFun(fts2mat(tmp));
        c(isnan(c) | isinf(c)) = 0;
        covRtn(i,:,:) = c;
    end
    covRtn(1:startidx-1,:,:) = repmat(covRtn(startidx,:,:),[startidx-1,1,1]);    
end

numReserved = max(myoption.lag)+2; % minimum periods reserved to facilicate optimization

W = NaN(numDate, numCMAFactor);
fval   = NaN(numDate,1);
latter_optm = NaN(numDate,1);
alpha     = NaN(numDate,numStock);
exitflag  = NaN(numDate,1);
conVal    = NaN(numDate,1);
[Aeq, Beq, lb, ub] = weightRestrict(w0);
w_prev = w0;

for t = numReserved:numDate
    if isempty(obj)  %%% Equally-Weighted
        W(t,:) = ones(numCMAFactor, 1) * 1/numCMAFactor;
    
    elseif strcmpi(obj,'riskpar') || strcmpi(obj,'riskpar-grp')         
        autocorr = nan(numCMAFactor,1);
        c = reshape(covRtn(t,:,:),[numCMAFactor,numCMAFactor,1]);
        %Multiply the covariance matrix by 1000 to increase the scale
        %otherwise tolerance level of fsolver won't be violated and we end
        %up getting equally weight everytime
        if strcmpi(obj,'riskpar')
            facgroup = [1:numel(factors)];
        elseif strcmpi(obj,'riskpar-grp')
            facgroup = myoption.facgroup;
        end
        try
            [optw, ~, exflag] = SolveRiskParity(c.*10000, facgroup); % solve for risk parity
        catch e            
            optw = W(t-1,:);
            exflag = 0;
        end
        %Get Previous period weight in case of failed fmincon method
        if exflag < 1
            optw = W(t-1,:);
        end
        
        for nl = 1:numCMAFactor
            autocorr(nl) = fts2mat(AC{nl}(t));
        end
        
        if any(isnan(autocorr)) % added by Louis on 2012-05-10, auto correlation check
            disp(['warning: at leaset one auto correlation of factors are NaN for t = ',num2str(t), ', auto correlation are set to 0']);
            autocorr(isnan(autocorr)) = 0;
        end
        
        % method 2 - minimize weight difference        
        optoptions=optimset('Algorithm','sqp');
        minAC = myoption.rho;
        opw0 = optw;
        try
            %Change in objective function from linear to quadratic deviation
             [optw, fval(t), exitflag(t)] = fmincon(@(x) mean((x - opw0).^2),opw0,-autocorr',-minAC,ones(1,numCMAFactor),1,lb,ub,[],optoptions);
            while exitflag(t) < 1 % if optimzation failed, loose the auto correlation constraint for that period
                minAC = minAC - 0.05;
                [optw, fval(t), exitflag(t)] = fmincon(@(x) mean((x - opw0).^2),opw0,-autocorr',-minAC,ones(1,numCMAFactor),1,lb,ub,[],optoptions);
            end
        catch e
            W(t,:) = W(t-1,:);
        end
        %Get Previous period weight in case of failed fmincon method
        W(t,:) = optw;
        if exitflag(t) < 1
            W(t,:) = W(t-1,:);
        end      
        
    else    
        % Then comes C and D which are from corrlation matrix of factors (including lagged factors)
        x = F(:,:,t)';
        y = F_prev(:,:,t)';
        pickedrows = ~any(isnan(x)|isnan(y), 2);
        x = x(pickedrows,:);
        y = y(pickedrows,:);
        C = COV(x, x);
        C_prev = COV(y, y);
        D = COV(x, y);

        % Calc mean and variance of IC over period [numReserved:s-1].
        % The reason of t-1 rather than s is based on reality:
        % at a time point, we know the factor values but we don't know returns 
        % in next period which are needed to calc IC (=corr(f_t, r_(t,t+1))).
        % So the IC info we can obtained at time s is from bwginning to s-1.
        rstart = max(t-myoption.ICWin(:,1),numReserved);
        rend   = min(numDate-1, t-1+myoption.ICWin(:,2));
        if any(rend <= rstart), continue; end;  % do nothing 
        IC_mean = myoption.ICMeanFun(IC(rstart(1):rend(1),:));
        IC_var  = myoption.ICCovFun(IC(rstart(2):rend(2),:));
        if t-1 > 0, w_prev = W(t-1,:)'; end
        if any(isnan(w_prev)), w_prev(:) = w0; end
        
        ub_ = ub;
        ub_(nanmean(IC(max(1,rend(1)-myoption.ICStopLossWin+1):rend(1),:)) < 0) = 0;
        
        try
            [W(t,:), fval(t), exitflag(t)] = fmincon(obj, w0, [], [], Aeq, Beq, lb, ub_, con, optimoption);
        catch e             
            W(t,:) = w_prev;
        end
        % if exit flag staus for fmincon is less than 1 
        % then optmization did not happen properly 
        % and the factor weights should be set to previous period weights 
        if exitflag(t) < 1
            W(t,:) = w_prev;
        end
        [~,~,latter_optm(t)] = obj(W(t,:)'); %#ok<RHSFN>
        if ~isempty(con)
            conVal(t) = con(W(t,:)');
        end
    end
    alpha(t,:) = W(t,:) * F(:,:,t);
end

%% Arranging returned things
date = stockRet.dates;
freq = stockRet.freq;
sid  = fieldnames(stockRet, 1);
fid  = cell(numCMAFactor,1);

i = 0;
for f = 1:numFactor
    for lag = 0:myoption.lag(f)
        i = i + 1;
        if isa(factors{f}, 'FacBase') && ischar(factors{f}.id) && ~isempty(factors{f}.id)
            fid{i} = factors{f}.id;
        else
            fid{i} = num2str(f, 'Fac%d');
        end
        if lag > 0
            fid{i} = [fid{i} num2str(lag, '_lag%d')];
        end
        fid{i}  = regexprep(fid{i}, '\s', '0');
    end
end

W         = myfints(date, W, fid, freq, 'OptimalWeights');
IR_optm   = myfints(date, fval, {'OptmObjVal'}, freq, 'Objective Function Value');
alpha     = myfints(date, alpha, sid, freq, 'Blending Alpha');
IC        = myfints(date, IC, fid, freq, 'Factor Information Ratio');
exitflag  = myfints(date, exitflag, {'OptmExitFlag'}, freq, 'Optimization Status');
latter_optm = myfints(date, latter_optm, {'OptmLatter'}, freq, 'Latter Part of Objective');
conVal    = myfints(date, conVal, {'Constraint'}, freq, 'Constraint Value');

%%------------- Nested Objective and Constraint Functions -----------------

function [v, g, latter] = IR_w(w, w_prev)
    if nargin < 2, w_prev = 0; end
    
    cache1 = w' * IC_var * w;
    cache2 = IC_mean * w;
    cache3 = w - w_prev;
    latter = myoption.lambda * (cache3'*cache3);
    v = -cache2 / sqrt(cache1) + latter;  % we want to max rather than min, so add -
    
    if nargout > 1  % calculate gradient
        g = -(IC_mean' - (cache2./cache1) * IC_var * w) / sqrt(cache1)...
            + 2 * myoption.lambda * cache3;
    end
end

function [v, g, latter] = IR_w_variant(w)
    cache1 = w' * IC_var * w;
    cache2 = IC_mean * w;
    latter = myoption.lambda * cache1;
    v = -cache2 + latter;
    g = -(IC_mean' - 2*myoption.lambda * IC_var * w);
end

function [v, g] = IR_diffw(w)
    [v, g] = IR_w(w, w_prev);
end

function [c, ceq, gc, gceq] = RHO_eq(w)
    c = [];
    cacheC = w' * C * w;
    cacheD = w' * D * w;
    ceq = -cacheD / cacheC...     % we want to max, so add a -
          + myoption.rho; % + 0.01;  % ceq has been prefixed with - in RHO(); also adjust for practical error
    
    if nargout > 2  % calculate gradient
        gc = [];
        gceq = -(D+D' - 2*cacheD/cacheC*C) * w ./ cacheC;
    end
end

function [c, ceq, gc, gceq] = RHO(w)
    [ceq, c, gceq, gc] = RHO_eq(w);
end

function [c, ceq, gc, gceq] = RHO_diffw_eq(w)
    c = [];
    cacheC = w' * C * w;
    cacheC_prev = w_prev' * C_prev * w_prev;
    cacheD = w' * D * w_prev;
    cacheS = sqrt(cacheC * cacheC_prev);
    ceq = -cacheD / cacheS...     % we want to max, so add a -
          + myoption.rho;  % ceq has been prefixed with - in RHO(); also adjust for practical error
      
    if nargout > 2
        gc = [];
        gceq = -(D * w_prev - cacheD / cacheC * C * w) / cacheS;
    end
end

function [c, ceq, gc, gceq] = RHO_diffw(w)
    [ceq, c, gceq, gc] = RHO_diffw_eq(w);
end

function [c, ceq, gc, gceq] = RHO_factor_eq(w)
    c = [];
    
    rho = NaN(numCMAFactor, 1);
    for fiter = 1:numCMAFactor
        rho(fiter) = corr(x(:,fiter), y(:,fiter), 'type','spearman','rows','pairwise');
    end
    
    ceq = - w' * rho + myoption.rho;
    
    if nargout > 2
        gc = [];
        gceq = -rho;
    end
end

function [c, ceq, gc, gceq] = RHO_factor(w)
    [ceq, c, gceq, gc] = RHO_factor_eq(w);
end

function [Aeq, Beq, lb, ub] = weightRestrict(w)
    Aeq = ones(1, length(w));
    Beq = 1;
    lb  = ones(size(w)) .* myoption.lb;
    ub  = ones(size(w)) .* myoption.ub;
end

end  % of optimize()

function xy = COV(x, y)
% Calculate E[(x-E(x))(y-E(y))].
assert(isequal(size(x), size(y)));

[nr,~] = size(x);
xc = bsxfun(@minus, x, sum(x,1)/nr);
yc = bsxfun(@minus, y, sum(y,1)/nr);
xy = (xc' * yc) / (nr - 1);
end

% this function is used to perform risk parity optimization
function [w, fval, exitflag] = SolveRiskParity(CovMat, group)
% CovMat is the covariance matrix 
% Group is a 1-D numeric vector indicating the group of assets
%       default group: each asset belongs to its own group, risk parity
%       will be applied among groups and within each group at the same time
    if nargin < 2
        group = [1:size(CovMat,1)];
    end
    assert(~any(any(isnan(CovMat))), 'covariance matrix cannot contain any NaN');
    assert(~any(any(isinf(CovMat))), 'covariance matrix cannot contain any Inf');
    % deal with the case when the variance is Zero
    variance = diag(CovMat);
    zeroidx = variance == 0;
    CovMatNew = CovMat(~zeroidx, ~zeroidx);
    groupNew = group(~zeroidx);
    
    nw = size(CovMat,1);
    w = zeros(nw, 1);
    w(zeroidx) = 0;  % set the factor weight to be 0 for those that has zero variance
    
    nNew = size(CovMatNew,1);
    w0 = repmat(1/nNew, nNew, 1);
    [wNew, fval, exitflag] = fsolve(@(x) RiskParityEquation(x, CovMatNew, groupNew), w0);
    w(~zeroidx) = wNew;
end

function [F, riskcon] = RiskParityEquation(wgt, CovMat, group)
% this function generates the risk parity equations
% Group is a 1-D numeric vector indicating the group of assets
%       default group: each asset belongs to its own group, risk parity
%       will be applied among groups and within each group at the same time
    if nargin < 3
        group = [1:size(CovMat,1)];
    end
    assert(numel(wgt) == size(CovMat,1), 'The size of weight and covariance not match');
    assert(numel(wgt) == numel(group), 'The size of weight and group not match');
    wgt = reshape(wgt, [numel(wgt),1]); % reshape the wgt to a column vector
    
    % calculate risk contribution from each asset
    riskcon = nan(size(wgt));
    for i = 1:numel(wgt)
        riskcon(i) = wgt(i)*CovMat(i,:)*wgt;
    end
    
    % find unique asset groups
    unigroup = unique(group);
    ngroup = numel(unigroup);
    group_risk = nan(ngroup,1);
    F = []; % function value
    for g = 1:ngroup
        gidx = find(group == unigroup(g));
        group_risk(g) = sum(riskcon(gidx)); % risk contribution from each group
        if numel(gidx) <= 1 % only one asset in current asset group
            continue;
        end
        
        tempF = nan(numel(gidx)-1,1);
        for i = 1:numel(gidx)-1
            tempF(i) = riskcon(gidx(i)) - riskcon(gidx(i+1)); % risk contribution within each group
        end
        F = [F; tempF];
    end
    
    F = [F; group_risk(2:end) - group_risk(1:end-1)];
    F = [F; sum(wgt) - 1]; % last equation: weight sum to one
end
