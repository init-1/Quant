
function [o, stat, model] = RegressionAnalysis(o, varargin)
    option.isgenreport = 1; % 1: generate report, 0: not generate report
    option.reportname = 'FA_RegressRpt'; % the report name generated  
    option.faclist = o.facinfo.name; % the list of factors that the analysis wants to run for 
    option.facgrp = [1:numel(o.factorts)]; % decide the factor group that the regression performed
    option.grpwgtmethod = 'EW'; % weighting method for factors within the group {'EW', 'IC', 'IR'}
    option.grpwgtwindow = nan; % average window if using moving average weighting method for grpwgtmethod
    option.sectordummy = 1; % decide whether to include sector dummy in regression
    option.sectorlevel = 2; % gics level of sector dummy in regression
    option.ctrydummy = 0; % 0 or 1: use country dummy or not
    option.riskneutral = 0; % decide whether to include EM risk factors in regression
    option.numriskfac = 5; % number of EM risk factors to neutralize
    option.otherriskfac = []; % other risk factors input by users that will be included in the regression
    option.buildmodel = 0; % decide whether to build a model on the input factors
    option.modelmethod = 'ALL'; % decide the method of building regression model: {'ALL', 'forward', 'backward'}
    option.predmethod = 'EMA'; % decide the method of predicting factor returns using exponential / simple moving average: {'EMA', 'SMA'}
    option.predwindow = Inf; % decide the window used to calculating moving average when predicting factor returns
    option.regweight = []; % the regression weight
    
    
    % deal with input option
    option = Option.vararginOption(option, {'isgenreport','reportname','faclist','facgrp','grpwgtmethod','grpwgtwindow','sectordummy','sectorlevel','ctrydummy','riskneutral','numriskfac','otherriskfac','buildmodel','modelmethod','predmethod','predwindow','regweight'}, varargin{:});
    if numel(option.facgrp) ~= numel(option.faclist)
        option.facgrp = [1:numel(option.faclist)]; 
        disp('Note: user specified factor list but didnot specify factor group, each factor will be treated as a distinct group');
    end

    %% step 1 - prepare data
    % step 1.1 - get the factor value normalized
    activeidx = ismember(o.facinfo.name, option.faclist);
    ishighthebetter = o.facinfo.ishigh(activeidx);
    activefacname = o.facinfo.name(activeidx);
    facts = o.factorts(activeidx);
    nfactor = numel(facts);
    facIC = cell(1,nfactor);
    factor_norm = cell(1,nfactor);
    for j = 1:nfactor
        factor_norm{j} = normalize(ishighthebetter(j)*facts{j}, 'method', 'norminv', 'weight', o.bmhd);
        facIC{j} = csrankcorr(factor_norm{j}, o.fwdret);
        % !!! a very important step to make sure that stock with zero
        % scores will NOT be used in regression, and will have zero weight
        % in factor portfolio
        factor_norm{j}(fts2mat(factor_norm{j}) == 0) = NaN; 
    end
    
    % step 1.2 - group the factor if necessary
    switch option.grpwgtmethod
        case 'EW'
            facwgt = ones(1, nfactor);
        case 'IC'
            facwgt = ftsmovavg([facIC{:}],option.grpwgtwindow,1);
            facwgt = lagts(facwgt,1,nan);
        case 'IR'
            facwgt = bsxfun(@rdivide, ftsmovavg([facIC{:}],option.grpwgtwindow,1), ftsmovstd([facIC{:}],option.grpwgtwindow,1));
            facwgt = lagts(facwgt,1,nan);
        otherwise
            facwgt = ones(1, nfactor);
            disp('Warning: invalid group weighting method, equally weight will be applied to factors within each group');
    end
    unigrp = sort(unique(option.facgrp));
    ngrp = numel(unigrp);
    grpfacts = cell(1,numel(option.facgrp));
    if ngrp == nfactor
        grpfacts = factor_norm;
    else       
        for g = 1:ngrp
            grpidx = option.facgrp == unigrp(g);
            grpfacts{g} = ftswgtmean(facwgt(:,grpidx), factor_norm{grpidx});
        end
    end
    grpfac_ac = nan(1,ngrp);
    for g = 1:ngrp % calculate auto correlation
        grpfac_ac(g) = nanmean(csrankcorr(grpfacts{g}, lagts(grpfacts{g},1,nan)));
    end
    
    % step 1.3 - put the constant, alpha factors and risk factors together
    constDummy = myfints(grpfacts{1}.dates, ones(size(grpfacts{1})), fieldnames(grpfacts{1},1));
    grpfacts = [{constDummy}, grpfacts];
    if option.sectordummy == 1
        sectorDummy = genSectorDummy(o.gics, option.sectorlevel); 
        grpfacts = [grpfacts, sectorDummy];
    end
    if option.ctrydummy == 1
        ctryDummy = genCtryDummy(o.ctry);
        grpfacts = [grpfacts, ctryDummy];
    end
    if option.riskneutral == 1
        [o, riskfacts] = genRiskFactor(o, option.numriskfac); 
        grpfacts = [grpfacts, riskfacts];
    end
    if ~isempty(option.otherriskfac)
        otherriskfac = option.otherriskfac;
        [otherriskfac{:}] = alignto(grpfacts{1}, option.otherriskfac{:}); 
        otherriskfac = reshape(otherriskfac, 1, numel(otherriskfac));
        grpfacts = [grpfacts, otherriskfac]; 
    end
    
    %% Step 2 - fit the regression
    % step 2.1 - fit univariate regression to get the raw factor return
    uvrbeta = cell(1, ngrp);
    uvrmeanbeta = nan(1, ngrp);
    uvr_t = nan(1, ngrp);
    for g = 1:ngrp
        tempbeta = csregress(o.fwdret, grpfacts([1,1+g]), 'weight', option.regweight);
        uvrbeta{g} = tempbeta(:,2);
        uvr_t(g) = nanmean(uvrbeta{g})./nanstd(uvrbeta{g}).*sqrt(nansum(~isnan(uvrbeta{g})));
        uvrmeanbeta(g) = nanmean(uvrbeta{g});
    end
    
    % step 2.2 - fit multivariate regression to get the 'pure' factor return after neutralizing risk factors
    mvrbeta = cell(1, ngrp);
    mvrmeanbeta = nan(1, ngrp);
    mvr_t = nan(1, ngrp);
    mvrFacPF = cell(1, ngrp);
    mvrError = cell(1, ngrp);
    for g = 1:ngrp
        [tempbeta, epsilon, ~, ~, ~, ~, ~, ~, tempFacPF] = csregress(o.fwdret, grpfacts([1,1+g,2+ngrp:numel(grpfacts)]), 'weight', option.regweight);
        mvrbeta{g} = tempbeta(:,2);
        mvr_t(g) = nanmean(mvrbeta{g})./nanstd(mvrbeta{g})*sqrt(nansum(~isnan(mvrbeta{g})));
        mvrmeanbeta(g) = nanmean(mvrbeta{g});
        mvrFacPF{g} = tempFacPF{2};
        mvrFacPF{g}(isnan(fts2mat(mvrFacPF{g})) & fts2mat(o.bmhd) > 0) = 0;
        mvrError{g} = epsilon;
    end
    
    stat.option = option;
    stat.factor_norm = factor_norm;
    stat.unigrp = unigrp;
    stat.grpfacts = grpfacts;
    stat.grpfac_ac = grpfac_ac;
    stat.uvrbeta = uvrbeta;
    stat.uvr_t = uvr_t;
    stat.uvrmeanbeta = uvrmeanbeta;
    stat.mvrbeta = mvrbeta;
    stat.mvr_t = mvr_t;
    stat.mvrmeanbeta = mvrmeanbeta;
    stat.mvrFacPF = mvrFacPF;
    stat.mvrError = mvrError;
    
    % step 2.3 - fit multivariate regression to get the 'pure' factor return after neutralizing other alpha factors + risk factors
    if option.buildmodel == 1 % if user wants to build a model on the input factors
        switch lower(option.modelmethod)
            case 'all'
                [beta, ~, ~, ~, ~, rethat, adjR2, R2contrib, facPF] = csregress(o.fwdret, grpfacts, 'weight', option.regweight);
                alphafacidx = 2:ngrp+1;
            otherwise
                [beta, ~, ~, ~, ~, rethat, adjR2, R2contrib, facPF, alphafacidx] = RegFacSelect(o.fwdret, grpfacts, 'riskfacidx', [ngrp+2:numel(grpfacts)], 'method', option.modelmethod);
        end
        if isempty(alphafacidx)
            error('no factors are selected into the model, process failed');
        end
        for j = 1:numel(facPF)
            facPF{j}(isnan(fts2mat(facPF{j})) & o.bmhd > 0) = 0;
        end
        meanbeta = nanmean(beta);
        tstat = nanmean(beta)./nanstd(beta)*sqrt(nansum(~isnan(beta(:,1))));        
        
        %% Step 3 - forecast the factor return & construct alpha
        [alpha, predbeta] = PredFacRtn(beta, grpfacts, alphafacidx, option.predmethod, option.predwindow);

        %% Step 5 - construct output
        model.option = option;
        model.factor_norm = factor_norm;
        model.unigrp = unigrp;
        model.grpfacts = grpfacts;
        model.beta = beta;
        model.meanbeta = meanbeta;
        model.tstat = tstat;
        model.adjR2 = adjR2;
        model.R2contrib = R2contrib;
        model.facPF = facPF;
        model.rethat = rethat;
        model.predbeta = predbeta;
        model.alphafacidx = alphafacidx;
        model.alpha = alpha;
    else
        disp('Warning: the paramter: buildmodel is set to 0, the output model will be empty');
        model = [];
    end
    
    %% Step 6 - generate report
    if option.isgenreport == 1
        disp('Generating the report - this takes a while');
        if ngrp ~= nfactor % if factors are grouped
            facname = Num2StrArray(unigrp);
        else
            facname = activefacname;
            facstruct = LoadFactorInfo(facname, 'MatlabFunction,FactorTypeId');
            classname = facstruct.MatlabFunction;
            if ischar(classname), classname = {classname}; end
            for j = 1:nfactor, facname{j} = [facname{j}, ' - ' classname{j}]; end
        end
        figid = cell(ngrp,1);
        for g = 1:ngrp
            if isempty(model)
                fts = [ftsmovsum(uvrbeta{g}, Inf, 1), ftsmovsum(mvrbeta{g}, Inf, 1)];
                legend = {['Raw: T = ',num2str(stat.uvr_t(g),'%3.1f')],['Pure: T = ',num2str(stat.mvr_t(g),'%3.1f')]};
                style = {{'-b', 'linewidth', 2},{'-r', 'linewidth', 2}};
            else
                fts = [cumsum(uvrbeta{g}), cumsum(mvrbeta{g}), cumsum(model.beta(:,g+1))];
                legend = {['Raw: T = ',num2str(stat.uvr_t(g),'%3.1f')],['Pure: T = ',num2str(stat.mvr_t(g),'%3.1f')],['Pure(Model): T = ',num2str(model.tstat(g+1),'%3.1f')]};
                style = {{'-b', 'linewidth', 2},{'-r', 'linewidth', 2},{'-g', 'linewidth', 2}};
            end
            fts(isnan(fts)) = 0;
            tsplot(fts, 'title', regexprep(['Cumulative Factor Return - ',facname{g}], '_|&', '\\$0'), 'style', style, 'legend', {{legend, 'location', 'NorthWest','fontsize', 8}});
            figid{g} = ['f', num2str(g)];
            saveas(gcf, [figid{g}, '.eps'], 'psc2');
            close;
        end

        % create table
        name = regexprep(facname, '_', '\\$0');
        name = reshape(name, ngrp, 1);
        name(1:2:end) = strcat('\rowcolor{cone}', name(1:2:end));
        name(2:2:end) = strcat('\rowcolor{ctwo}', name(2:2:end));
        if isempty(model)
            data = [stat.grpfac_ac', 100*stat.uvrmeanbeta', stat.uvr_t', 100*stat.mvrmeanbeta', stat.mvr_t', nan(ngrp,1), nan(ngrp,1)];
        else
            data = [stat.grpfac_ac', 100*stat.uvrmeanbeta', stat.uvr_t', 100*stat.mvrmeanbeta', stat.mvr_t', 100*model.meanbeta(2:ngrp+1)', model.tstat(2:ngrp+1)'];
        end
        content = [name, Num2StrArray(data, '% 10.2f')];
        columnname = {'Factor(Grp)', 'Auto-$\rho$', 'Mean uni-$\beta$ (%)','T(uni-$\beta$)','Mean multi-$\beta$ (%)','T(multi-$\beta$)','Mean model-$\beta$ (%)','T(model-$\beta$)'};

        % output to excel
        xlswrite([option.reportname,'.xlsx'], [columnname; [name, num2cell(data)]]);

        % output to pdf
        p = PDFDoc(option.reportname);
        p.table('Summary', columnname, content, 'l c c c c c c c', 'landscape');
        p.figure(figid,'width=8cm, height = 4cm', '', 2, 5);
        p.run;
        pdffigs = strcat(figid, '.pdf');
        delete(pdffigs{:});
    else
        disp('Users choose not to generate report, function ends');
    end
end

function sectorDummy = genSectorDummy(gics, level) % this function generates a cell array of myfints which represent sector dummy variables
    sector = fts2mat(gics);
    scale = 100^(4-level);
    sector = floor(sector/scale);
    unisec = unique(sector);
    unisec(isnan(unisec)) = [];
    sectorDummy = cell(1,numel(unisec)-1);
    for i = 1:numel(unisec)-1
        temp = double((sector == unisec(i)));
        sectorDummy{i} = myfints(gics.dates, temp, fieldnames(gics,1));
    end
end

function [o, riskfacts] = genRiskFactor(o, numriskfac) % this function generates a cell array of myfints which represent risk factors 
    if isempty(o.riskmodel)
        disp('Loading Risk Model from DB - this will take some time');
        o = LoadRiskModel(o);
    else
        disp('Risk model found in the object will be used');
    end
    assert(numriskfac <= size(o.riskmodel.exposure, 3), 'The number of risk factors input is larger than the size of risk model');
    riskfacts = cell(1, numriskfac);
    for i = 1:numriskfac
        riskfacts{i} = o.riskmodel.exposure(:,:,i);
    end
end

function ctryDummy = genCtryDummy(Ctry) % Ctry is a myfints of number in this case
    CtryMat = fts2mat(Ctry);
    uniqCtry = unique(CtryMat);
    ctryDummy = cell(1,numel(uniqCtry)-1);
    for i = 1:numel(uniqCtry)-1 % note that you should only create n - 1 dummies for n classifications
        temp = double((CtryMat == uniqCtry(i)));
        ctryDummy{i} = myfints(Ctry.dates, temp, fieldnames(Ctry,1));
    end
end
