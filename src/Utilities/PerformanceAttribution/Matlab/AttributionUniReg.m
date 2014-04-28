function TSResult = AttributionUniReg(actwgt, fwdret, bmhd, alphats, facwgt, factorts, facinfo)
% Perform attribution calculation based on univariate regression approach

outdatedidx = ~ismember(fieldnames(facwgt, 1), facinfo.FactorId);
facwgt(:,outdatedidx) = [];
[ndate, ~] = size(fwdret);
nfactor = numel(factorts);
factorname = fieldnames(facwgt,1);
TC = cscorr(actwgt, alphats, 'rows', 'complete');
activeness = cssum(abs(actwgt))./2;

fwdret_dm = bsxfun(@minus, fwdret, csmean(fwdret)); % de-meaned forward return
actRtn = cssum(fwdret_dm.*actwgt); % portfolio active return

%% Calculation
FacRet = myfints(fwdret_dm.dates, nan(size(facwgt)), factorname);
WgtFacRet = myfints(fwdret_dm.dates, nan(size(facwgt)), factorname);
FacExp = myfints(fwdret_dm.dates, nan(size(facwgt)), factorname);
SpecRet = cell(1,nfactor);
FacContrib = cell(1,nfactor);
WgtSpecRet = cell(1,nfactor);
WgtFacContrib = cell(1,nfactor);
for i = 1:numel(factorts)
%     [beta, epsilon] = csregress(fwdret_dm, factorts(i), 'weight', bmhd); % find factor return
    [beta, epsilon] = csregress(fwdret_dm, factorts(i));
    % portfolio level 
    FacExp(:,i) = nansum(factorts{i}.*actwgt, 2);
    FacRet(:,i) = fts2mat(beta); % factor return of factor i
    WgtFacRet(:,i) = fts2mat(beta).*fts2mat(facwgt(:,i));
    
    % stock level
    SpecRet{i} = epsilon; % specific return other than factor i
    FacContrib{i} = bsxfun(@times, factorts{i}, beta); % contribution from factor i for each stock
    WgtSpecRet{i} = bsxfun(@times, SpecRet{i}, facwgt(:,i)); % weighted sepcific return
    WgtFacContrib{i} = bsxfun(@times, FacContrib{i}, facwgt(:,i)); % weighted factor contribution
    
end

StockRet_Factor = ftsnansum(WgtFacContrib{:}); % stock return explained by factors
StockRet_Spec2 = ftsnansum(WgtSpecRet{:}); % stock return explained by specific return
StockRet_Spec = fwdret_dm - StockRet_Factor; % stock return explained by specific return
ActFacContrib = FacExp.*WgtFacRet; % active factor contribution to portfolio
TotFacContrib = cssum(ActFacContrib); % total contirbution from all factors
TotSpecContrib = cssum(StockRet_Spec.*actwgt); % active portfolio level specific return contribution

% style contribution
facstyle = facinfo.FactorTypeId;
uniqstyle = [1,2,3,4,5]; % sort(unique(facstyle));
stylename = {'Value','Technical','Quality','Sentiment','Growth'};
nstyle = numel(stylename);
styleidx = cell(1,nstyle);
StockRet_Style = cell(1,nstyle);
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
        style_contrib(:,s) = nansum(ActFacContrib(:,styleidx{s}),2);
        StockRet_Style{s} = ftsnansum(WgtFacContrib{[styleidx{s}]});
    end
end

% return contribution from each stock
stock_contrib = fwdret_dm.*actwgt;% in active portfolio

%% Prepare time series result
TSResult.actwgt = actwgt;
TSResult.bmhd = bmhd;
TSResult.fwdret = fwdret;
TSResult.fwdret_dm = fwdret_dm;
TSResult.alphaScore = alphats;
TSResult.factorts = factorts;
TSResult.totalbmwgt = cssum(bmhd);
TSResult.netactwgt = cssum(actwgt);
TSResult.nsec = cssum(~isnan(bmhd));
TSResult.TC = TC;
TSResult.activeness = activeness;
TSResult.actRtn = actRtn;
TSResult.FacRet = FacRet;
TSResult.FacExp = FacExp;
TSResult.StockRet_Factor = StockRet_Factor;
TSResult.StockRet_Spec = StockRet_Spec;
TSResult.stock_contrib = stock_contrib;
TSResult.ActFacContrib = ActFacContrib;
TSResult.TotFacContrib = TotFacContrib;
TSResult.TotSpecContrib = TotSpecContrib;
TSResult.facwgt = facwgt;
TSResult.styleidx = styleidx;
TSResult.style_exp = style_exp;
TSResult.style_netwgt = style_netwgt;
TSResult.style_grswgt = style_grswgt;
TSResult.style_contrib = style_contrib;
TSResult.StockRet_Style = StockRet_Style;
        
end

