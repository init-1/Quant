function GetSummary(o, faclist, savepath, filename)
% generate a excel file with factor summaries 

statfaclist = cell(1,numel(o.statistics));
for i = 1:numel(o.statistics)
    statfaclist{i} = o.statistics{i}.facname;
end

if nargin < 2
    faclist = statfaclist;
    savepath = '';
    filename = ['FA_Summary_',o.univname];
elseif nargin < 3
    savepath = '';
    filename = ['FA_Summary_',o.univname];
end

facidx = ismember(statfaclist, faclist);
facname = statfaclist(facidx);
stat = o.statistics(facidx);
nFactor = numel(stat);
style = nan(nFactor,1);
if FactorAnalyzer.isFactorId(facname)
    facstruct = LoadFactorInfo(facname, 'MatlabFunction,FactorTypeId');
    classname = facstruct.MatlabFunction;
    style = facstruct.FactorTypeId;
    if ~iscell(classname), classname = {classname}; end
    for j = 1:nFactor, facname{j} = [facname{j}, ' - ' classname{j}]; end
end
facname = reshape(facname,[numel(facname),1]);

neutralstyle = o.statistics{1}.neutralstyle;
nTable = numel(neutralstyle);
filename = [savepath,filename,'.xlsx'];
colname = {'Factor', 'Style', 'Coverage(TTM)', 'AutoCorr', 'mean(IC)', 'sigma(IC)', 'IR(IC)', 'min(IC)', 'MDD(IC)', 'mean(FacRtn)', 'sigma(FacRtn)', 'IR(FacRtn)', 'min(FacRtn)', 'MDD(FacRtn)'};
for i = 1:nTable
    cvg = nan(nFactor,1);
    ac = nan(nFactor,1);
    meanIC = nan(nFactor,1);
    sigmaIC = nan(nFactor,1);
    IRIC = nan(nFactor,1);
    minIC = nan(nFactor,1);
    mddIC = nan(nFactor,1);
    meanFR = nan(nFactor,1);
    sigmaFR = nan(nFactor,1);
    IRFR = nan(nFactor,1);
    minFR = nan(nFactor,1);
    mddFR = nan(nFactor,1);

    for j = 1:nFactor
        tempstat = stat{j};
        cvg(j) = nanmean(tempstat.coverage(max(end-11,1):end,:));
        ac(j) = nanmean(tempstat.autocorr);
        meanIC(j) = nanmean(tempstat.IC{i});
        sigmaIC(j) = nanstd(tempstat.IC{i});
        IRIC(j) = tempstat.IRIC(i);
        minIC(j) = nanmin(tempstat.IC{i},[],1);
        mddIC(j) = nanmin(FtsDrawDown(tempstat.IC{i}),[],1);
        meanFR(j) = nanmean(tempstat.LS{i});
        sigmaFR(j) = nanstd(tempstat.LS{i});
        IRFR(j) = tempstat.IRLS(i);
        minFR(j) = nanmin(tempstat.LS{i},[],1);
        mddFR(j) = nanmin(FtsDrawDown(tempstat.LS{i}),[],1);
    end
    content = num2cell([style, cvg, ac, meanIC, sigmaIC, IRIC, minIC, mddIC, meanFR, sigmaFR, IRFR, minFR, mddFR]);
    data = [colname; [facname, content]];

    tableName = [neutralstyle{i},'Neutral'];
    xlswrite(filename,data,tableName);
end 

end % of function