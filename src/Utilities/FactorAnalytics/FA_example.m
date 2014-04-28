%% create Factor Analyzer object
% parameter for creating object
aggid = '0064990100'; % the aggid of the index - define the universe
startdate = '2000-01-31'; % start date of data
enddate = '2012-04-30'; % end date of data
isprod = 0; % 1 for getting data from production (live data), 0 for getting data from development (backtest data)
freq = 'M'; % frequency of data
dateParam = {'BusDays',0}; % extra date parameters to control the dates of time series
nbucket = 5; % number of neutralization bucket used for styles such as b2p, beta, and mcap
univname = 'MSWO'; % name of universe, arbitraryly decided by users
ctrylist = {}; % a country list that defines a subset from the universe
facinfo.name = {'F00001','F00005','F00018'}; % set the factorid that will be included in the object

% construct the object
o = FactorAnalyzer(facinfo,aggid,startdate,enddate,isprod,freq,ctrylist,nbucket,dateParam,univname); 

%% Generate report with default settings
% calculate statistics and get report with default setting
o = CalcStatistics(o,startdate,enddate); 
GetSummary(o);

%% Report customization
% basic customization
gicslevel = 2; % GICS level 2 neutral
neutralstyle = {'ctrysect'}; % customize neutralization style to be ctry/sector
facOrAlpha = {'F00001','F00018'}; % pick a subset of factors to run
custplot = {'ByCtry', 'LongShort', 'ScoreByMcap', 'RtnByMcap', 'ScoreByLiq', 'RtnByLiq'}; % choose plots on the report, starting from the 5th plots
Savepath = 'Y:\Louis.Luo\'; % save path of the report
summaryfile = 'Summary001'; % name of the summary excel file

% advanced customization 
secids = fieldnames(o.bmhd,1); % get security list
CurCtryGICS = LoadSecInfo(secids,'Country,IsoCurId,SubIndustId','','',0); % retreive current GICS, country, and currency info
Ctry = CurCtryGICS.Country;
Cur = CurCtryGICS.IsoCurId;
GICS = CurCtryGICS.SubIndustId;

% 1. user customized universe
% set the customized universe to be financial sector of the original benchmark
custuniv.name = {'MSWOFIN'};
custuniv.data = o.bmhd(:,floor(GICS/10^6) == 40); 

% 2. user customized neutralization style - currency neutral
uniqCur = unique(Cur);
currency = o.bmhd;
currency(:,:) = NaN;
for i = 1:numel(uniqCur)
    ccyidx = ismember(Cur, uniqCur{i});
    currency(:,ccyidx) = i;
end

% 3. user customized neutralization style - currency neutral
regionctrymap.region = {'USA','EUR','EUR','EUR','EUR','EUR','EUR','EUR','EUR','EUR','EUR','JAP','RES','RES','RES'};
regionctrymap.ctry   = {'USA','CHE','GBR','DEU','FRA','DNK','IRL','SWE','BEL','ESP','FIN','JPN','AUS','ISR','CAN'};
region = o.bmhd;
region(:,:) = NaN;
uniqRegion = unique(regionctrymap.region);
for i = 1:numel(uniqRegion)
    regionidx = ismember(Ctry, regionctrymap.ctry(ismember(regionctrymap.region, uniqRegion(i)))); % find the index of region i based on the region ctry mapping and the country id of benchmark
    region(:,regionidx) = i;
end

% create customized style parameter 
custstyle.name = {'currency', 'region'};
custstyle.data = {currency, region};

%% Regenerate report with customized settings
[o, o_new] = CalcStatistics(o,startdate,enddate,'gicslevel',1,'facOrAlpha',facOrAlpha,'neutralstyle',neutralstyle ...
    ,'custstyle',custstyle,'custuniv',custuniv,'custplot',custplot,'savepath',Savepath); % o_new will only contain the stocks from customized universe
GetSummary(o, facOrAlpha, Savepath, summaryfile);

%% Generate alpha from selected factor list and calculate long-short signal weighted portfolio return
selectfaclist = {'F00001','F00018'}; 
result = AnalyzeAlpha(o, 'faclist', selectfaclist, 'normdata', o.gics, 'normlevel', 1, 'wgtmethod', 'EW');

%% Load Risk Model (optional)
o = LoadRiskModel(o);

%% Run regression analysis
% selected factor list to perform regression analysis
selectfaclist = {'F00001','F00018'}; 
% individual alpha factor + sector dummy
[o, stat, model] = RegressionAnalysis(o, 'faclist', selectfaclist, 'reportname', 'Regression001','sectordummy', 1, 'riskneutral', 0); 
% individual alpha factor + sector dummy + 5 EM risk factor
[o, stat, model] = RegressionAnalysis(o, 'faclist', selectfaclist, 'reportname', 'Regression002','sectordummy', 1, 'riskneutral', 1, 'numriskfac', 5); 

% create currency dummy variables
CurDummy = cell(1, numel(uniqCur));
for i = 1:numel(uniqCur)
    CurDummy{i} = o.bmhd;
    CurDummy{i}(:,:) = 0;
    CurDummy{i}(:,ismember(Cur, uniqCur{i})) = 1;
    CurDummy{i}(isnan(o.bmhd)) = 0;
end

% individual alpha factor + sector dummy + 5 EM risk factor + customized risk factor
[o, stat, model] = RegressionAnalysis(o, 'faclist', selectfaclist, 'reportname', 'Regression003','sectordummy', 1, 'riskneutral', 1, 'numriskfac', 5, 'otherriskfac', CurDummy);

% multiple alpha factors + sector dummy + 5 EM risk factor + customized risk factor
[o, stat, model] = RegressionAnalysis(o, 'faclist', selectfaclist, 'reportname', 'Regression004','sectordummy', 1, 'riskneutral', 1, 'numriskfac', 5, 'otherriskfac', CurDummy, 'buildmodel', 1);

% secids = fieldnames(o.bmhd,1);
% CurCtry = LoadSecInfo(secids,'Country,IsoCurId','','',0);
% Ctry = CurCtry.Country;
% Cur = CurCtry.IsoCurId;
% uniqCur = unique(Cur);
% CurDummy = cell(1, numel(uniqCur));
% currency = o.bmhd;
% currency(:,:) = NaN;
% for i = 1:numel(uniqCur)
%     currency(:,ismember(Cur, uniqCur{i})) = i;
%     CurDummy{i} = o.bmhd;
%     CurDummy{i}(:,:) = 0;
%     CurDummy{i}(:,ismember(Cur, uniqCur{i})) = 1;
%     CurDummy{i}(isnan(o.bmhd)) = 0;
% end
% 
% ctryindgrp = bsxfun(@plus, o.ctry*10^4, floor(fts2mat(o.gics)/10^4));
% currencyindgrp = bsxfun(@plus, currency*10^4, floor(fts2mat(o.gics)/10^4));
% 
% AlphaResultEW = o.AnalyzeAlpha('faclist', selectlist, 'normdata', o.gics,'normlevel', 1);
% 
% otherriskfac = [RegionDummy];
% %
% [o, stat, model] = RegressionAnalysis(o, 'faclist', selectlist, 'reportname', 'MSHC_Regression_Cur','buildmodel', 0, 'sectordummy', 0, 'sectorlevel', 2, 'riskneutral',0,'otherriskfac',otherriskfac);
% [o, stat, model] = RegressionAnalysis(o, 'faclist', selectlist, 'reportname', 'MSHC_Regression_CurRisk','buildmodel', 0, 'sectordummy', 0, 'sectorlevel', 2, 'riskneutral',1,'numriskfac',5,'otherriskfac',otherriskfac);
% 
% [o, stat, model] = RegressionAnalysis(o, 'faclist', selectlist, 'reportname', 'MSHC_Regression_gics','buildmodel', 0, 'sectordummy', 1, 'sectorlevel', 2, 'riskneutral',0);
% [o, stat, model] = RegressionAnalysis(o, 'faclist', selectlist, 'reportname', 'MSHC_Regression_gicsRisk','buildmodel', 0, 'sectordummy', 1, 'sectorlevel', 2, 'riskneutral',1,'numriskfac',5);
% 
% [o, stat, model] = RegressionAnalysis(o, 'faclist', {'F00001'}, 'reportname', 'MSHC_Regression_gicsRegion','buildmodel', 0, 'sectordummy', 1, 'sectorlevel', 2, 'riskneutral',0,'otherriskfac',otherriskfac);
% [o, stat, model] = RegressionAnalysis(o, 'faclist', selectlist, 'reportname', 'MSHC_Regression_gicsCurRisk','buildmodel', 0, 'sectordummy', 1, 'sectorlevel', 2, 'riskneutral',1,'numriskfac',5,'otherriskfac',otherriskfac);
% 
% [o, stat, model] = RegressionAnalysis(o, 'faclist', selectlist, 'reportname', 'MSHC_Regression_Risk','buildmodel', 0, 'sectordummy', 0, 'sectorlevel', 2, 'riskneutral',1,'numriskfac',5);
% 
% 
% nfactor = numel(selectlist);
% factor_neutral = cell(nfactor,1);
% for j = 1:nfactor
%     factor_neutral{j} = normalize(stat.mvrFacPF{j},'weight', o.bmhd);
%     facRtn{j} = factorPFRtn(factor_neutral{j},o.fwdret,o.bmhd); 
%     facIC{j} = csrankcorr(factor_neutral{j},o.fwdret); 
% end
% 
% Alpha = ftsnanmean(factor_neutral{:});


% [o, stat, model] = RegressionAnalysis(o, 'faclist', rawselectlist, 'reportname', 'MSHC_Regression_FacSelection','buildmodel', 1, 'modelmethod', 'backward', 'sectordummy', 1, 'sectorlevel', 2, 'riskneutral',0,'otherriskfac',otherriskfac);

