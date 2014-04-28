%% Description
% this function runs performance attribution on factor models
% Author: Louis Xun Luo (2012-03-25)


function StrategyResult = Main_Attribution(strategyid, startdate, enddate, varargin)

option.method = 'signalPF'; % 'signalPF' for signal weighted portfolio approach, 'uniReg' for univaraite regression
option.isprod = 1; % 1 for production mode, 0 for development mode
option.userholding = []; % user input holding could be a myfints

option = Option.vararginOption(option, {'method','isprod','userholding'}, varargin{:});

%% parameters
rundate = enddate;
defaultsdate = addtodate(datenum(rundate), -1, 'Y');
startnum = min(datenum(startdate), defaultsdate);
startdate = datestr(startnum, 'yyyy-mm-dd');
datastartdate = datestr(addtodate(datenum(startdate),-12,'M'), 'yyyy-mm-dd'); % 1 more year data will be retrieved in case dealing with lagged factors, etc.

% Load Rebalancing Date here
if isempty(option.userholding)
    Rebalance = runSP('QuantStrategy', ['select distinct date from quantstrategy.dbo.strategyholdingts where strategyid = ''',strategyid,''''], {}); 
    ReblcDate = datenum(Rebalance.date);
else
    ReblcDate = option.userholding.dates;
end

%% Load Strategy Level Data
[strategyinfo, aggid] = LoadStrategyInfo_V2(strategyid, option.isprod);
modellist.modelid = strategyinfo.modelid;
modellist.modelname = strategyinfo.modelname;
ModelResult = cell(1, numel(strategyinfo.modelid));

alphats_all = LoadAlphaTS(strategyinfo, datastartdate, rundate, option.isprod); % alpha
[pfhd_all, bmhd_all, ~] = LoadFacStrategyHoldingTS(strategyid, aggid, 1, datastartdate, rundate); % holding
if ~isempty(option.userholding) % replace the portfolio holding with the user input holding
    pfhd_all = alignto(bmhd_all, option.userholding);
end

secids_all = fieldnames(bmhd_all,1);

% other data
gics_all = LoadQSSecTS(secids_all, '913', 0, datastartdate, rundate);
stockTRI_all = LoadRawItemTS(secids_all, 'D001410474', datastartdate, rundate); % total return
price_usd = LoadRawItemTS(secids_all, 'D001410415', datastartdate, rundate); % price in usd
price_usd = alignfields(price_usd, bmhd_all, 'union');
riskmodel = RiskEMA(aggid,rundate,0);
faccov = riskmodel.faccov;
exposure_all = riskmodel.exposure;
specrisk_all = riskmodel.specrisk;

% fill the gap in the holding
pfhd_all = FillHoldingGap(pfhd_all, price_usd);
bmhd_all = FillHoldingGap(bmhd_all, price_usd);
actwgt_all = pfhd_all - bmhd_all;

% align 
[alphats_all, stockTRI_all, gics_all] = alignto(bmhd_all, alphats_all, stockTRI_all, gics_all);
alphats_all = backfill(alphats_all, 60, 'row');
stockTRI_all = backfill(stockTRI_all, 60, 'entry');
gics_all = backfill(gics_all, 60, 'entry');
fwdret_all = leadts(stockTRI_all,1,nan)./stockTRI_all - 1; % calculate return after alignment

% align risk model
nonidx = ~ismember(fieldnames(specrisk_all,1), secids_all);
specrisk_all(:,nonidx) = [];
exposure_all(:,nonidx,:) = [];

[exposure_all, specrisk_all, actwgt_all] = alignfields(exposure_all, specrisk_all, actwgt_all, 1, 'union');

% riskcon_mat = CalcRiskContrib(fts2mat(actwgt_all(end,:)), fts2mat(faccov), fts2mat(exposure), fts2mat(specrisk));

%% loop for each model
for j = 1:numel(strategyinfo.modelid)
    disp(['running model: ',num2str(strategyinfo.modelid(j))]);
    % Load Model Level Data
    modelid = strategyinfo.modelid(j);
    modelinfo = LoadModelInfo(strategyinfo, modelid, option.isprod);
    modelfactorinfo = LoadModelFactorInfo_V2(strategyinfo, modelid, startdate, enddate, option.isprod);
    
    submodellist.submodelid = modelinfo.submodelid;
    submodellist.name = modelinfo.name;
    if ~iscell(submodellist.name), submodellist.name = {submodellist.name}; end
    num_submodel = numel(submodellist.submodelid);
    SubModelResult = cell(num_submodel, 1);
    for m = 1:num_submodel
        %% get existing sub model data 
        disp(['running submodel: ',num2str(submodellist.submodelid(m))]);
        % load sub model specific data
        submodelid = submodellist.submodelid(m);
        if strcmpi(strategyinfo.type, 'bld')
            submodelsecids = runSP('QuantWorkSpace', 'rpw.usp_GetSubModelSecId', {strategyid, modelid, submodelid, datastartdate, rundate, aggid, option.isprod});
            if isempty(submodelsecids)
                disp('Warning: submodel does not have any stocks');
                continue;
            end
            submodelsecids = submodelsecids.secid;
            idxsec = ismember(secids_all, submodelsecids);
            bmhd = bmhd_all(:,idxsec);
            actwgt = actwgt_all(:,idxsec);
            alphats = alphats_all(:,idxsec);
            gics = gics_all(:,idxsec);
            fwdret = fwdret_all(:,idxsec);
            exposure = exposure_all(:,idxsec,:);
            specrisk = specrisk_all(:,idxsec);
        else
            bmhd = bmhd_all;
            actwgt = actwgt_all;
            alphats = alphats_all;
            gics = gics_all;
            fwdret = fwdret_all;
			exposure = exposure_all;
            specrisk = specrisk_all;
        end
        
        %% load factors for sub-model
        secids = fieldnames(bmhd,1);
        factorid = modelfactorinfo.factorid(modelfactorinfo.submodelid == submodelid);
        facinfo = LoadFactorInfo(factorid,{'MatlabFunction,HigherTheBetter,FactorTypeId'},option.isprod);
        facinfo.name = facinfo.MatlabFunction;
        rawfactorts = cell(size(factorid));
        nfactor = numel(factorid);
        nlag = modelinfo.lag(m);

        for i = 1:nfactor
            if option.isprod == 1
                rawfactorts{i} = LoadFactorTSProd(secids, factorid{i}, datastartdate, rundate, 1);
            else
                rawfactorts{i} = LoadFactorTS(secids, factorid{i}, datastartdate, rundate, 1);
            end
            rawfactorts{i} = rawfactorts{i}*facinfo.HigherTheBetter(i);
        end
        
        % create nfac-by-(nlag+1) cell array: lagRawfacts, the 1st row is the factorts with 0-lag, the i-th row are factors with (i-1) lags
        lagRawfacts = cell(nfactor, nlag+1);
        for i = 1:nfactor
            tmprawfac = aligndates(rawfactorts{i}, 'M');
            for k = 1:nlag+1
                if k == 1
                    lagRawfacts{i,k} = rawfactorts{i};
                else
                    lagRawfacts{i,k} = lagts(tmprawfac, k-1, NaN);
                end
            end
            [lagRawfacts{i,:}] = alignto(bmhd, lagRawfacts{i,:});
            lagRawfacts(i,:) = cellfun(@(c) {backfill(c,60,'row')}, lagRawfacts(i,:));
        end                   
        
        %% normalize factors
        % load the neutralization factor if if alpha of this strategy is neutralized w.r.t. certain factor instead of gics
        isFacNeutral = 0;
        if strcmpi(strategyinfo.type, 'bld')
            if ~isnan(modelinfo.FactorBucket{m}) 
                neutralfac = LoadFactorDecile(secids, modelinfo.FactorBucket{m},datastartdate,enddate,1,nan,modelinfo.BucketNum(m),option.isprod,bmhd);
                isFacNeutral = 1;
            end
        end
        if isFacNeutral == 0;
            neutralfac = gics;
            level = modelinfo.gicslevel(m);
        else
            level = 'customized';
        end
        
        % create 1-by-(nlag+1) cell array: lagNeutralfac, the i-th col is the neutralization factor with(i-1) lag
        lagNeutralfac = cell(1, nlag+1);
        tmpNeutralfac = aligndates(neutralfac, 'M');
        lagNeutralfac{1} = neutralfac;
        for k = 2:nlag+1
            lagNeutralfac{k} = lagts(tmpNeutralfac, k-1, NaN);
        end
        [lagNeutralfac{:}] = alignto(bmhd, lagNeutralfac{:});
        lagNeutralfac = cellfun(@(c) {backfill(c,60,'row')}, lagNeutralfac);
        
        % normalize here
        normfactorts = cell(size(lagRawfacts));
        for i = 1:nfactor
            for k = 1:nlag+1
                normfactorts{i,k} = normalize(lagRawfacts{i,k}, 'method', 'norminv', 'weight', bmhd, 'GICS', lagNeutralfac{k}, 'level', level);
            end
        end

        %% load / combine factor weight
        facwgt = LoadFactorWeightTS(modelid, submodelid, datastartdate, rundate, strategyinfo, modelfactorinfo, option.isprod);
        facwgt = cellfun(@(c) {orderField(c,factorid)}, facwgt);
        [facwgt{:}] = aligndates(facwgt{:}, bmhd.dates);
        facwgt = cellfun(@(c) {backfill(c,60,'row')}, facwgt);
        
        % combine factors with the same factorid but different lags
        factorts = cell(nfactor, 1);
        for i = 1:nfactor
            tmplagwgt = myfints(facwgt{1}.dates, nan(numel(facwgt{1}.dates), nlag+1));
            for k = 1:nlag+1 
                tmplagwgt(:,k) = fts2mat(facwgt{k}(:,i));
            end
            tmplagwgt(isnan(tmplagwgt)) = 0; % weight could be NaN when the submodel changed factors before
            nonexistidx = all(fts2mat(tmplagwgt) == 0,2);
            factorts{i} = ftswgtmean(tmplagwgt, normfactorts{i,:});
            factorts{i}(nonexistidx, :) = 0;
        end
        facwgt = ftsnansum(facwgt{:});
        facwgt(isnan(fts2mat(facwgt))) = 0;
        facwgt = bsxfun(@rdivide, facwgt, nansum(abs(facwgt), 2));
        
        % align alpha, factor weight and factorts to Rebalancing Date, and then backfill
        origdate = alphats.dates;
        [alphats, factorts{:}, facwgt] = aligndates(alphats, factorts{:}, facwgt, ReblcDate);
        [alphats, factorts{:}, facwgt] = aligndates(alphats, factorts{:}, facwgt, origdate);
        alphats = backfill(alphats, inf, 'row');
        factorts = cellfun(@(x) {backfill(x, inf, 'row')}, factorts);
        facwgt = backfill(facwgt, inf, 'row');
        
        %% Truncate the time series by the startdate
        [actwgt, fwdret, bmhd, alphats, facwgt, factorts{:}]= TruncateTS(startdate, enddate, actwgt, fwdret, bmhd, alphats, facwgt, factorts{:});
        
        %% Attribution calculation begins here
        switch lower(option.method)
            case 'signalpf'
                TSResult = AttributionSignalPF(actwgt, fwdret, bmhd, alphats, facwgt, factorts, facinfo);
            case 'unireg'
                TSResult = AttributionUniReg_V2(actwgt, fwdret, bmhd, alphats, facwgt, factorts, facinfo);
        end
        [~, TSResult.variance] = CalcRiskContrib(fts2mat(actwgt(end,:)), fts2mat(faccov), fts2mat(exposure), fts2mat(specrisk));
        SubModelResult{m}.facinfo = facinfo;
        SubModelResult{m}.TS = TSResult;
    end
    
    ModelResult{j}.submodellist = submodellist;
    ModelResult{j}.TS = AggregateTS(SubModelResult, 0, option.method);
    ModelIdx = ismember(secids_all, fieldnames(ModelResult{j}.TS.bmhd,1));
    [~, ModelResult{j}.TS.variance] = CalcRiskContrib(...
        fts2mat(actwgt_all(end,ModelIdx)), fts2mat(faccov), fts2mat(exposure_all(1,ModelIdx,:)), fts2mat(specrisk_all(1,ModelIdx)));
    ModelResult{j}.SubModelResult = SubModelResult;
end

StrategyResult.strategyid = strategyid;
StrategyResult.modellist = modellist; 
StrategyResult.TS = AggregateTS(ModelResult, 1, option.method);
[~, StrategyResult.TS.variance] = CalcRiskContrib(...
        fts2mat(actwgt_all(end,:)), fts2mat(faccov), fts2mat(exposure_all), fts2mat(specrisk_all));
StrategyResult.ModelResult = ModelResult; 

%% Get result between default dates
LastWeekEnd = PeriodBeginDate(rundate, 'W');
LastMonthEnd = PeriodBeginDate(rundate, 'M');
LastQtrEnd = PeriodBeginDate(rundate, 'Q');
LastYearEnd = PeriodBeginDate(rundate, 'Y');
PFBeginDate = actwgt_all.dates(find(any(~isnan(fts2mat(actwgt_all)),2),1,'first'));
InceptionDate = runSP('QuantStrategy',['select min(Date) Date from dbo.strategyholdingts where strategyid = ''',strategyid,''''],{});
if ~isempty(InceptionDate)
    if PFBeginDate > datenum(InceptionDate.Date)
        disp('Warning: The input startdate is later than the actual inception date of the strategy, ITD result will be from the input startdate!');
    end
end

StrategyResult = ResultBetweenDates(StrategyResult, LastWeekEnd, rundate, 'WTD', option.method);
StrategyResult = ResultBetweenDates(StrategyResult, LastMonthEnd, rundate, 'MTD', option.method);
StrategyResult = ResultBetweenDates(StrategyResult, LastQtrEnd, rundate, 'QTD', option.method);
StrategyResult = ResultBetweenDates(StrategyResult, LastYearEnd, rundate, 'YTD', option.method);
StrategyResult = ResultBetweenDates(StrategyResult, PFBeginDate, rundate, 'ITD', option.method); % inception to date

%% output
% GenAttributionReport(StrategyResult, filename);
end

