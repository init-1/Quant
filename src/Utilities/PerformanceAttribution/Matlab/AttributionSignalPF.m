function TSResult = AttributionSignalPF(actwgt, fwdret, bmhd, alphats, facwgt, factorts, facinfo)
% Perform attribution calculation based on alpha weighted portfolio + constraint portfolio approach
secids = fieldnames(bmhd,1);
outdatedidx = ~ismember(fieldnames(facwgt, 1), facinfo.FactorId);
facwgt(:,outdatedidx) = [];
[ndate, ~] = size(fwdret);
nfactor = numel(factorts);
factorname = fieldnames(facwgt,1);
TC = cscorr(actwgt, alphats, 'rows', 'complete');
activeness = cssum(abs(actwgt))./2;

% alpha contribution
actRtn = cssum(fwdret.*actwgt); % portfolio active return
[alphaRtn, ~, ~, alphaPF] = factorPFRtn(alphats, fwdret, bmhd); % signal weighted return
alphaCappedRtn = factorPFRtn(alphats, fwdret, bmhd,'wgtmethod','BMSigWgtCapped'); % short-side capped signal weighted return
alpha_contrib = bsxfun(@times, activeness, alphaRtn);

% factor contribution
factorRtn = myfints(fwdret.dates, nan(ndate, nfactor), factorname); 
factorPF = cell(size(factorts));
factorExp = myfints(fwdret.dates, nan(ndate, nfactor), factorname); 

alphaidx = any(~isnan(fts2mat(alphats)),2);
factorPFtmp = cell(size(factorts));
for k = 1:numel(factorts)
    factorExp(:,k) = nansum(actwgt.*factorts{k},2);
    [tempFacRtn, ~, ~, factorPF{k}] = factorPFRtn(factorts{k}, fwdret, bmhd); 
    factorPF{k}(isnan(factorPF{k})) = 0; % set the factor portfolio weight to be zero if it is nan, otherwise may cause error when fitting regression
    factorRtn(:,k) = fts2mat(tempFacRtn);
    factorPFtmp{k} = factorPF{k}(alphaidx,:);
end

regfacwgt = facwgt;
if numel(secids) > numel(factorts)
    beta = csregress(alphaPF(alphaidx,:), factorPFtmp); % get the weight from regression
%             beta = csregress(alphats(alphaidx,:), factortmp); % get the weight from regression
    regfacwgt(alphaidx,:) = fts2mat(beta);
else
    disp('Warning: number of stocks are less than number of factors, regression cannot be fit');
end
factor_contrib = bsxfun(@times, regfacwgt.*factorRtn, activeness);

% style contribution
facstyle = facinfo.FactorTypeId;
uniqstyle = [1,2,3,4,5]; % sort(unique(facstyle));
stylename = {'Value','Technical','Quality','Sentiment','Growth'};
nstyle = numel(stylename);
styleidx = cell(1,nstyle);
style_netwgt= myfints(facwgt.dates, zeros(ndate, nstyle), stylename);
style_grswgt= myfints(facwgt.dates, zeros(ndate, nstyle), stylename);
style_contrib = myfints(facwgt.dates, zeros(ndate, nstyle), stylename);
for s = 1:numel(uniqstyle)
    styleidx{s} = find(ismember(facstyle, uniqstyle(s)));
    facinfo.name(styleidx{s}) = strcat(['(',stylename{s}(1),')'], facinfo.name(styleidx{s}));
    if ~isempty(styleidx{s})
        style_netwgt(:,s) = nansum(facwgt(:,styleidx{s}),2);
        style_grswgt(:,s) = nansum(abs(facwgt(:,styleidx{s})),2);
        style_contrib(:,s) = nansum(factor_contrib(:,styleidx{s}),2);
    end
end

% error contribution (discrepancy btw factor and alpha)
error_contrib = alpha_contrib - cssum(factor_contrib);

% constraint contribution
alphawgt = bsxfun(@times, alphaPF, activeness);
constr_wgt = actwgt - alphawgt;
constraint_contrib = cssum(constr_wgt.*fwdret);

% return contribution from each stock
stock_contrib = fwdret.*actwgt;% in active portfolio
stock_constr_contrib = constr_wgt.*fwdret;% in constraint portfolio
stock_alpha_contrib = alphawgt.*fwdret;% in alpha portfolio

%% Prepare time series result
TSResult.actwgt = actwgt;
TSResult.bmhd = bmhd;
TSResult.fwdret = fwdret;
TSResult.alphaScore = alphats;
TSResult.constr_wgt = constr_wgt;
TSResult.alphawgt = alphawgt;
TSResult.factorts = factorts;
TSResult.totalbmwgt = cssum(bmhd);
TSResult.netactwgt = cssum(actwgt);
TSResult.nsec = cssum(~isnan(bmhd));
TSResult.TC = TC;
TSResult.activeness = activeness;
TSResult.actRtn = actRtn;
TSResult.alphaRtn = alphaRtn;
TSResult.alphaCappedRtn = alphaCappedRtn;
TSResult.alpha_contrib = alpha_contrib;
TSResult.constraint_contrib = constraint_contrib;
TSResult.factorRtn = factorRtn;
TSResult.factorExp = factorExp;
TSResult.facwgt = facwgt;
TSResult.regfacwgt = regfacwgt;
TSResult.factor_contrib = factor_contrib;
TSResult.error_contrib = error_contrib;
TSResult.styleidx = styleidx;
TSResult.style_netwgt = style_netwgt;
TSResult.style_grswgt = style_grswgt;
TSResult.style_contrib = style_contrib;
TSResult.stock_contrib = stock_contrib;
TSResult.stock_constr_contrib = stock_constr_contrib;
TSResult.stock_alpha_contrib = stock_alpha_contrib;
        
end