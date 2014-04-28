% [ds setting dsparam] = LoadAXData(filename, signal, aggid, dates, startport, varargin)
% filename      - Path to save the .mat file
% signal        - Can be either 'StrategyId' or a myfints containing alpha
% aggid         - Universe defined by the benchmark.
% dates         - Cell array of dates
% startport     - Can be either initial portfolio size in USD or myfints
% riskmodel     - Risk Model: Either EMA or Barra
% tcmodel       - Transaction Cost Model: Either Flat, Simple or QSG
% islive        - Live workspace indicator
% numbuckets    - Number of buckets for the bucket attributes
% modelclass     - xts of user-defined metagroup classification

function [ds setting dsparam] = LoadAXData(filename, signal, aggid, dates, startport, varargin)
%% Date check for startport and signal
if isa(signal,'myfints')
    assert(length(ismember(datenum(dates),signal.dates)) == length(datenum(dates)),'Signals does not exist on all the dates specified.');
end

if isa(startport,'myfints')
    assert(ismember(min(datenum(dates)),startport.dates),'Starting Portfolio does not exist on the dates specified.');
end
%% Trim dates based on Risk Model availability
TRACE('Running Date Check on Risk Model ... ');
riskmodel.Factor_1 = NaN;
i = 1;
dates = datenum(dates);
initcount = length(dates);
while all(isnan(riskmodel.Factor_1)) == 1
    riskmodel = DB('QuantTrading').runSql('axioma.GetEMRiskExp_Full',datestr(dates(i),'yyyy-mm-dd'),aggid,0);
    if all(isnan(riskmodel.Factor_1))
        dates(i) = 0;
    end
    i = i + 1;
end
dates(dates == 0) = [];
TRACE([num2str(initcount - length(dates)) ' dates removed ... done\n']);

%% Initalize Parameter
TRACE('Initializing Parameters ... ');
dsparam.signal = signal;
dsparam.aggid = aggid;
dsparam.dates = datenum(dates);
dsparam.startport = startport;

paramname = {'riskmodel','tcmodel','islive','numbuckets','modelclass'};
defaultvalue = {'ema','flat',0,5,[]};
inputparam = varargin(1:2:end-1);
inputvalue = varargin(2:2:end);
% display illegal parameter names detected
if ~isempty(inputparam(~ismember(inputparam,paramname)))
    illegal = inputparam(ismember(inputparam,paramname));
    warning(['The following parameter(s) are illegal and will not be used:',sprintf(' %s',illegal{:})]);
end
% assign parameter value
for i=1:numel(paramname)
    dsparam.(paramname{i}) = inputvalue{ismember(inputparam,paramname(i))};
    if isempty(dsparam.(paramname{i}))
        dsparam.(paramname{i}) = defaultvalue{i};
    end
end
TRACE('done\n');
%% Create Data Set
ds = Defaults.dataset(dsparam);

%% Create default setting
setting = Defaults.setting(dsparam);

%% Save file
save(filename,'ds','dsparam','setting');

end