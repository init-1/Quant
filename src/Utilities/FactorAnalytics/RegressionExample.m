% example: how to neutralize factors by regression and generate factor report

%% Parameters: 
aggid = '0064106801'; % the aggid of the index - define the universe
startdate = '2002-01-31'; % start date of data
enddate = '2012-04-30'; % end date of data
isprod = 0; % 1 for getting data from production (live data), 0 for getting data from development (backtest data)
freq = 'M'; % frequency of data
dateParam = {'BusDays',0}; % extra date parameters to control the dates of time series
nbucket = 5; % number of neutralization bucket used for styles such as b2p, beta, and mcap
univname = 'MSHC'; % name of universe, arbitraryly decided by users
ctrylist = {}; % a country list that defines a subset from the universe
facinfo.name = {'F00257','F00260','F00263'}; % set the factorid that will be included in the object

%% create factor analyzer object: o
o = FactorAnalyzer(facinfo,aggid,startdate,enddate,isprod,freq,ctrylist,nbucket,dateParam,univname); 

%% customize risk factors you want to neutralize (in this case)
secids = fieldnames(o.bmhd,1);

% 1. major risk factors
PB = LoadFactorTS(secids,'F00001',startdate,enddate,0,'M');
Size = LoadFactorTS(secids,'F00072',startdate,enddate,0,'M');
Vol = LoadFactorTS(secids,'F00080',startdate,enddate,0,'M');
[PB, Size, Vol] = alignto(o.bmhd, PB, Size, Vol);
PB(:,:) = WinsorizeData(fts2mat(PB), 'pct', 0.02, 'nsigma', 5);
Size(:,:) = WinsorizeData(fts2mat(Size), 'pct', 0.02, 'nsigma', 5);
Vol(:,:) = WinsorizeData(fts2mat(Vol), 'pct', 0.02, 'nsigma', 5);
PB = normalize(PB,'method','norminv','weight',o.bmhd);
Size = normalize(Size,'method','norminv','weight',o.bmhd);
Vol = normalize(Vol,'method','norminv','weight',o.bmhd);

% 2. Put all risk factors together to get a cell array
riskfac = [{PB}, {Size}, {Vol}];

%% Run regression to get factor portfolio
selectlist = {'F00257','F00260','F00263'};

[o, stat] = RegressionAnalysis(o, 'faclist', selectlist,...
    'isgenreport', 0,... % no report
    'sectordummy', 1,... % neutralize sector dummies
    'sectorlevel', 2,... % sector dummy set to GICS level 2
    'ctrydummy', 1, ... % use country dummy in regression
    'riskneutral', 0,... % don't neutralize EM risk fators
    'otherriskfac', riskfac); % other risk factor is the country dummy + risk factor

facPFStruct.name = selectlist;
facPFStruct.data = stat.mvrFacPF;

%% NEW!!! Adjust the factor portfolio by specific risk
facPFStruct.name = cell(size(selectlist));
facPFStruct.data = cell(size(selectlist));
for i = 1:numel(stat.mvrFacPF)
    window = 12; % the window used to estimate specific variance
    regWeight = GetSpecAdjustWgt(stat.mvrError{i},o.fwdret, 'window', window);   
    [~, tmpstat] = RegressionAnalysis(o, 'faclist', selectlist(i),...
        'isgenreport', 0,... % no report
        'sectordummy', 1,... % neutralize sector dummies
        'sectorlevel', 2,... % sector dummy set to GICS level 2
        'ctrydummy', 1,... % use country dummy in regression
        'riskneutral', 0,... % don't neutralize EM risk fators
        'otherriskfac', riskfac,... % other risk factor is the country dummy + risk factor
        'regweight', regweight); % supply the weight to the regression to get specific risk-adjusted pure factor portfolio
    facPFStruct.data{i} = tmpstat.mvrFacPF{1};
    facPFStruct.name{i} = selectlist{i};
end


%% Generate factor report using factor portfolios
gicslevel = 1; 
neutralstyle = {'ctry','gics'}; % customize neutralization style to be ctry/sector
custplot = {'ByCtry', 'LongShort', 'ScoreByMcap', 'RtnByMcap', 'ScoreByLiq', 'RtnByLiq'}; % choose plots on the report, starting from the 5th plots
Savepath = 'P:\';

[o, o_new] = CalcStatistics(o,startdate,enddate,'facOrAlpha', facPFStruct...
    ,'isnormalize',0 ... % don't normalize the factor value again
    ,'gicslevel',gicslevel,'neutralstyle',neutralstyle ...
    ,'custplot',custplot,'savepath',Savepath); % o_new will only contain the stocks from customized universe

GetSummary(o);




