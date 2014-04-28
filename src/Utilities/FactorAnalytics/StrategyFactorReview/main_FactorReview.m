%% This script will generate report for the factors which have abnormal performance in the specific strategy. 
%% Need to add the searching path to '\QuantStrategy\Analytics\Utility\FactorAnalytics\'.
%% User can customize the parameters in opt.

strategyid = 'FAC_MSCI_WORLDHCV2'; % specify the factor model here
startdate = '2010-12-31';       % specify the investigate period here    
enddate = '2012-08-31';

opt.cumrtn3M = -0.05; % latest 3M cummulative return less than -5%;
opt.rtn3M = 0;        % latest 3M monthly return all less than 0;
opt.rtn1M = -0.05;    % latest 1M monthly return less than -5%;
opt.liquidqt = [3,4,5]; % define which quintiles are liquid, if you define as [1 2 3 4 5], which means all the quintiles are liquid
opt.liquidrtn3M = 0;  % latest 3M liquid return all less than 0;
opt.cvgchg = 0.1;     % current coverage - lag 1M coverage;
opt.despchg = 0.4;     % current dipersion - lag 1M dispersion;
opt.facmeanchg = 0.4;  % mean raw factor value change;
opt.facmedianchg = 0.4;% median raw factor value change;
opt.autocorrchg = 0.2; % factor autocorrelation change;
opt.rtnbandwidth = 2;  % Define the factor return band, number of std

freq = 'M'; 
dateParam = {'BusDays',0}; 
nbucket = 5;
ctrylist = {};
isprod = 1;
savepath = ['.\' strategyid '\'];
if exist(strategyid, 'dir') ~= 7 
    mkdir(strategyid);
end

q = ['select distinct t2.modelid,t3.submodelid,t0.aggid from commonsqlprod2.quantstrategy.dbo.strategymstr t0 ' ...
        ' inner join  commonsqlprod2.quantstrategy.bld.strategymodel t1 on t0.alphaid = t1.strategyid' ...
        ' inner join  commonsqlprod2.quantstrategy.bld.modelmstr t2 on t1.modelid = t2.modelid ' ...
            ' inner join commonsqlprod2.quantstrategy.bld.modelsubmodel t3 on t1.modelid = t3.modelid ' ...
                ' where strategyid = ''' strategyid ''' order by t2.modelid,t3.submodelid'];
strategyinfo = runSP('quantstrategy',q);

if ~iscell(strategyinfo.aggid)
    strategyinfo.aggid = {strategyinfo.aggid};
end
primaryaggid = unique(strategyinfo.aggid);
primaryaggid = primaryaggid{1};

modelsubmodel = unique([strategyinfo.modelid,strategyinfo.submodelid],'rows');

%Get the model factor mapping and submodelparameter mapping
q = ['select distinct modelid, submodelid, factorid from commonsqlprod2.quantstrategy.bld.modelfactormap where ' ...
           ' modelid in (select distinct modelid from bld.strategymodel where strategyid = ''' strategyid ''' ) order by modelid, submodelid, factorid'];
modelfactormap = runSP('quantstrategy',q);
facuniv = sort(unique(modelfactormap.factorid));

%Get the submodel parameter for the neutralization style
q = ['select modelid,submodelid,gicslevel,factorbucket,bucketnum from commonsqlprod2.quantstrategy.bld.submodelparameter where ' ...
        ' modelid in (select distinct modelid from bld.strategymodel where strategyid = ''' strategyid ''' ) order by modelid, submodelid'];        
submodelparam = runSP('quantstrategy',q);
% 
%% Step 1 - Create factor analyzer object for the whole universe and all the underlying factors for the strategy
facinfo.name = facuniv;
o = FactorAnalyzer(facinfo,primaryaggid,startdate,enddate,isprod,freq,ctrylist,nbucket,dateParam,strategyid);
save(['o_' strategyid '.mat'],'o');

% load('o_FAC_MSCI_WORLDHCV2.mat');


%% Step 2 - Calculate statistics for model submodel factor list
ngroup = size(modelsubmodel,1);
o_modelsubmodel = cell(ngroup,1);
custstyle = cell(ngroup,1);
for i = 1:ngroup    
    
    modelid = modelsubmodel(i,1);
    submodelid = modelsubmodel(i,2);
    
    disp(['Running modelid - ' num2str(modelid) ' and submodelid - ' num2str(submodelid)]);

    %Step 2.1 - Get the customized universe
    submodelsecids = runSP('QuantWorkSpace', 'rpw.usp_GetSubModelSecId', {strategyid, modelid, submodelid, startdate, enddate, primaryaggid, isprod});    
    submodelsecids = submodelsecids.secid;
    custuniv.name = {[num2str(modelid) '-' num2str(submodelid)]};    
    custuniv.data = o.bmhd(:,ismember(fieldnames(o.bmhd,1),submodelsecids));
    
    %Step 2.2 - Get the factor list    
    faclist = modelfactormap.factorid(modelfactormap.modelid == modelid & modelfactormap.submodelid == submodelid);
    
    %Step 2.3 - Get the neutral style        
    neutralstyle = {};    
    if ~iscell(submodelparam.factorbucket)
        submodelparam.factorbucket = {submodelparam.factorbucket};
    end
    facbucketid = submodelparam.factorbucket{submodelparam.modelid == modelid & submodelparam.submodelid == submodelid};
    if ~isnan(facbucketid)        
        bucketnum = submodelparam.bucketnum(submodelparam.modelid == modelid & submodelparam.submodelid == submodelid);
        custstyle{i}.name = {facbucketid};
        custstyle{i}.data = {FactorAnalyzer.LoadFacDecile(fieldnames(o.bmhd,1),facbucketid,startdate,enddate,isprod,o.freq,bucketnum,o.bmhd,o.dateParam{:})};
    else
        gicslevel = submodelparam.gicslevel(submodelparam.modelid == modelid & submodelparam.submodelid == submodelid);
        custstyle{i}.name = {['gics' num2str(gicslevel)]};
        custstyle{i}.data = {o.gics};        
        custstyle{i}.data{:}(:,:) = floor(fts2mat(o.gics./10^(8-2^gicslevel)));
    end    
    
    [~,o_modelsubmodel{i}] = CalcStatistics(o,startdate,enddate,'savepath',savepath,'custuniv',custuniv,'facOrAlpha',faclist,'neutralstyle',neutralstyle,'custstyle',custstyle{i},'isplot',0);      
    o_modelsubmodel{i} = CalcPeriodStatistics(o_modelsubmodel{i},'startdate',datestr(addtodate(datenum(enddate),-6,'M'),'yyyy-mm-dd'),'enddate',enddate,'suffix','P6M');    
    
end
% 
 save([strategyid '.mat'],'o_modelsubmodel','o');

%  load('FAC_MSCI_EAFEv2.mat');

%Generate factor summary in excel
filename = ['FA_Summary_' strategyid]; 
for i = 1:2
    [selectunivname, selectfaclist] = GetFactorSummary(o_modelsubmodel,savepath,strategyid, opt);
end

%Generate the factor reports for selected ones
univname = cellfun(@(x){x.univname}, o_modelsubmodel);
neutralstyle = {};
uniobjlist = unique(selectunivname);
for i = 1:numel(uniobjlist)
    selectidx = ismember(selectunivname,uniobjlist{i});
    objid = find(ismember(univname,uniobjlist{i}));
    CalcStatistics(o_modelsubmodel{objid}, startdate, enddate, 'savepath', savepath, 'facoralpha',selectfaclist(selectidx),'custstyle',custstyle{objid},'neutralstyle',neutralstyle,'fileprefix',uniobjlist{i},'isplot',1);
end

