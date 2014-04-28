
function TSResult = AttributionUniReg_V2(actwgt, fwdret, bmhd, alphats, facwgt, factorts, facinfo)
% Perform attribution calculation based on univariate regression approach - regress on alpha directly

outdatedidx = ~ismember(fieldnames(facwgt, 1), facinfo.FactorId);
facwgt(:,outdatedidx) = [];
[ndate, nstock] = size(fwdret);
nfactor = numel(factorts);
factorname = fieldnames(facwgt,1);
TC = cscorr(actwgt, alphats, 'rows', 'complete');
activeness = cssum(abs(actwgt))./2;

fwdret_dm = bsxfun(@minus, fwdret, csmean(fwdret)); % de-meaned forward return
actRtn = cssum(fwdret_dm.*actwgt); % portfolio active return

%% Calculation
% alpha level
[alphaRtn, epsilon, ~, ~, ~, ~, ~, ~, alphaPF] = csregress(fwdret_dm, {alphats}); % find alpha return
alphaPF = alphaPF{:};

StockRet_Alpha = bsxfun(@times, alphats, alphaRtn);
StockRet_Alpha(isnan(StockRet_Alpha)) = 0;
StockRet_Spec = fwdret_dm - StockRet_Alpha;
alphaExp = nansum(alphats.*actwgt, 2);
alpha_contrib = bsxfun(@times, alphaRtn, alphaExp);
spec_contrib = cssum(StockRet_Spec.*actwgt); % active portfolio level specific return contribution

% factor level
factorRtn = myfints(fwdret.dates, nan(ndate, nfactor), factorname); 
factorPF = cell(size(factorts));

alphaidx = any(~isnan(fts2mat(alphats)),2);
factorPFtmp = cell(size(factorts));
for k = 1:numel(factorts)
    [tempFacRtn, ~, ~, factorPF{k}] = factorPFRtn(factorts{k}, fwdret_dm, bmhd); 
    factorPF{k}(isnan(factorPF{k})) = 0; % set the factor portfolio weight to be zero if it is nan, otherwise may cause error when fitting regression
    factorRtn(:,k) = fts2mat(tempFacRtn);
    factorPFtmp{k} = factorPF{k}(alphaidx,:);
end

regfacwgt = facwgt;
beta = csregress(alphaPF(alphaidx,:), factorPFtmp); % get the weight from regression
%             beta = csregress(alphats(alphaidx,:), factortmp); % get the weight from regression
regfacwgt(alphaidx,:) = fts2mat(beta);
factor_contrib = bsxfun(@times, regfacwgt.*factorRtn, alphaExp);

% style contribution
facstyle = facinfo.FactorTypeId;
uniqstyle = [1,2,3,4,5]; % sort(unique(facstyle));
stylename = {'Value','Technical','Quality','Sentiment','Growth'};
nstyle = numel(stylename);
styleidx = cell(1,nstyle);
style_exp = myfints(facwgt.dates, zeros(ndate, nstyle), stylename);
style_netwgt = myfints(facwgt.dates, zeros(ndate, nstyle), stylename);
style_grswgt = myfints(facwgt.dates, zeros(ndate, nstyle), stylename);
style_contrib = myfints(facwgt.dates, zeros(ndate, nstyle), stylename);
for s = 1:numel(uniqstyle)
    styleidx{s} = find(ismember(facstyle, uniqstyle(s)));
    facinfo.name(styleidx{s}) = strcat(['(',stylename{s}(1),')'], facinfo.name(styleidx{s}));
    if ~isempty(styleidx{s})
        style_exp(:,s) = nansum(actwgt.*ftswgtmean(facwgt(:,styleidx{s}), factorts{styleidx{s}}),2);
        style_netwgt(:,s) = nansum(facwgt(:,styleidx{s}),2);
        style_grswgt(:,s) = nansum(abs(facwgt(:,styleidx{s})),2);
        style_contrib(:,s) = nansum(factor_contrib(:,styleidx{s}),2);
    end
end

% return contribution from each stock
stock_contrib = fwdret_dm.*actwgt;% in active portfolio

% factor score structured as a xts
facdata = nan(ndate, nstock, nfactor);
facname = cell(nfactor,1);
for f = 1:nfactor
    facdata(:,:,f) = fts2mat(factorts{f});
    facname{f} = [facinfo.name{f}, '(', facinfo.FactorId{f}(end-2:end), ')'];
end
factorScore = xts(bmhd.dates, facdata, fieldnames(bmhd,1), facinfo.name); 

%% Prepare time series result
TSResult.actwgt = actwgt;
TSResult.bmhd = bmhd;
TSResult.fwdret = fwdret;
TSResult.fwdret_dm = fwdret_dm;
TSResult.alphaScore = alphats;
TSResult.factorScore = factorScore;
TSResult.totalbmwgt = cssum(bmhd);
TSResult.netactwgt = cssum(actwgt);
TSResult.nsec = cssum(~isnan(bmhd));
TSResult.TC = TC;
TSResult.activeness = activeness;
TSResult.actRtn = actRtn;
TSResult.StockRet_Alpha = StockRet_Alpha;
TSResult.StockRet_Spec = StockRet_Spec;
TSResult.stock_contrib = stock_contrib;
TSResult.factor_contrib = factor_contrib;
TSResult.alpha_contrib = alpha_contrib;
TSResult.spec_contrib = spec_contrib;
TSResult.facwgt = facwgt;
TSResult.styleidx = styleidx;
TSResult.style_netwgt = style_netwgt;
TSResult.style_grswgt = style_grswgt;
TSResult.style_exp = style_exp;
TSResult.style_contrib = style_contrib;
        
end

