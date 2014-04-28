function [results, stats, strout, opt] = AXOptimize(name,ds,setting,parameter,assetcon,attribcon,rebaldates,obj_extra,cons_extra)
% name     : Name for the optimization - resultant workspace will be named after this
% ds       : AXDataSet Object     
% setting  : setting structure generated using LoadAXSetting or Defaults.setting
% parameter: parameter structure generated using LoadAXParameter or Defaults.parameter
% assetcon : Holding Constraint - takes the form of lb(i) <= w(i) <= ub(i)
%            Parameter should be a cell array of struture with fieldnames
%            A, type, name, priority, isactive. 
%            Field A is a (t x n x 3) xts. The four fieldnames in the 3rd dimension
%            should be {'min','max','maxviolation'}.
%            A.desc refers to the scope of the fields. (i.e.
%            asset, selection, member, aggregate.
% attribcon: Attribute Level Constraint - takes the form of lb <= A*w <= ub
%            Parameter should be a cell array of structure with fieldnames
%            A, ub, lb, name, maxviolation, priority and isactive. 
%            Field A is a myfints with the attribute values. 
%            Field ub, lb are the upper and lower bounds of the constraints
%            Field isactive indicates whether the vector w is active weight
%            (isactive = 1) or portfolio weight (isactive = 0).
%            name refers to the name of group created in ds
%            A.desc refers to the scope of the fields. (i.e.
%            asset, selection, member, aggregate.
%% Initialize Parameters
if ~exist('rebaldates','var')
    rebaldates = ds.dates;
end

%% Create Rebalancing
rebal = Defaults.rebalancing(setting);
rebal_begin = rebal;
rebal_begin.budgetsize = parameter.budgetsize;

%% Create Objective
if exist('obj_extra','var')
    if ~isempty(obj_extra)
        obj = obj_extra;
    else
        obj = Defaults.objective(parameter);
    end
else
    obj = Defaults.objective(parameter);
end

%% Create Period Independent constraints
% Sanity Check for Model Classification
if ~ismember({'MODEL'},keys(ds.attribute))
    parameter.modelbet.value = Inf;
end
cons = Defaults.constraints(parameter);

if numel(rebaldates) == 1
    cons.initial = cons.period;
end

%% Add Extra Constraints
if exist('cons_extra','var')
    if ~isempty(cons_extra)
        cons.initial = [cons.initial ; cons_extra.initial];
        cons.period = [cons.period ; cons_extra.period];
    else
        cons_extra = {};
    end
else
    cons_extra = {};
end

%% Define Local Universe
if setting.isshort == 1
    % include cash asset in local universe for short scenarios
    setting.localinc = strcat(setting.localinc,',CASH');
end
lu_inc = textscan(upper(setting.localinc),'%s','Delimiter',',');
lu_inc = lu_inc{1};
if ~isnan(setting.localexc)
    lu_exc = textscan(upper(setting.localexc),'%s','Delimiter',',');
    lu_exc = lu_exc{1};
else
    lu_exc = {};
end

%% Create Strategy (for Report)
strout = AXStrategy('Rebalance' ...
    , 'objective', obj ...
    , 'constraints', cons.period ...
    , 'isConstraintHierarchy', 1 ...
    , 'isAllowCrossover', setting.isshort ...
    , 'isAllowShorting', setting.isshort ...
    , 'included', lu_inc ...
    , 'excluded', lu_exc);

%% Create Strategy (for Axioma)
% Set defaults if parameters were not inputted
if ~exist('assetcon','var')
    assetcon = {};
else
    if ~iscell(assetcon)
        assetcon = {assetcon};
    end
end

if ~exist('attribcon','var')
    attribcon = {};
else
    if ~iscell(attribcon)
        attribcon = {attribcon};
    end
end

% Add appropritate dataset for customized constraint
for i=1:length(attribcon)
    TRACE(['Loading Customized Dataset ' attribcon{i}.name ' ... ']);
    ds.add(upper(attribcon{i}.name),attribcon{i}.A,'GROUP');
    TRACE('done\n');
end

% Add asset/group level holdings and trade constraints
conslist = Defaults.spancons(ds,parameter,assetcon,attribcon,rebaldates,cons_extra);

% Create Container.Map for strategy and rebalance
if length(ds.dates) > 1
    strts = cell(1,length(ds.dates));
    rebalts = cell(1,length(ds.dates));
    for i=1:length(ds.dates)
        strts{i} = getStrategy(obj,conslist{i},1,setting.isshort,lu_inc,lu_exc);
        if i==1 || ds.dates(i) == min(rebaldates)
            rebalts{i} = rebal_begin;
        else
            rebalts{i} = rebal;
        end
    end
else
    strts = getStrategy(obj,conslist{1},1,setting.isshort,lu_inc,lu_exc);
    rebalts = rebal;
end
strts = containers.Map(ds.dates, strts);
rebalts = containers.Map(ds.dates, rebalts);

%% Create Optimization
opt = AXOptimization(ds,strts,rebalts);

%% Run Axioma Optimization
if ~exist('Workspace','dir')
    mkdir('Workspace');
end
if ~exist('Result','dir')
    mkdir('Result');
end
if isempty(name)
    results = opt.runsmart(rebaldates);
else
    results = opt.runsmart(rebaldates, ['Workspace\REBALANCE_' name '_']);
end

if length(keys(results)) == length(rebaldates)
    try
        stats = opt.report(results,['REPORT_' name], rebaldates, strout);
        save2file(['Result\results_' name '.mat']);
    catch e
        save2file(['Result\results_' name '.mat']);
        rethrow(e);
    end
else
    save2file(['Result\results_' name '.mat']);
    stats = [];
end

function str = getStrategy(obj,cons,hierarchy,isshort,inc,exc)
    str = AXStrategy('Rebalance' ...
                , 'objective', obj ...
                , 'constraints', cons ...
                , 'isConstraintHierarchy', hierarchy ...
                , 'isAllowCrossover', isshort ...
                , 'isAllowShorting', isshort ...
                , 'included', inc ...
                , 'excluded', exc);
end

function err = save2file(filename)
    issuccess = 0;
    while(issuccess == 0)
        try
            if exist(filename,'file')
                delete(filename);
            end
            save(filename);
            issuccess = 1;
            err = {};
        catch err
            TRACE('Unable to save file - retrying...\n');
            err = {err};
        end
    end
    
end

end