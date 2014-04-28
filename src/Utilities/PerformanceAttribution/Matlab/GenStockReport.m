function GenStockReport(StrategyResult, Period, filename)
% table report for stock performance attribution on each sub model level
% only works for the method = 'uniReg'
if nargin < 3
    filename = ['StockSummary_',StrategyResult.strategyid];
end

SR = StrategyResult;
MR = SR.ModelResult;
g = 0;
p = PDFDoc(filename);
p.writeln('\setlength\tabcolsep{3pt}');
for i = 1:numel(SR.modellist.modelname)    
    for j = 1:numel(MR{i}.submodellist.name)
        if isempty(MR{i}.SubModelResult{j})
            continue;
        end
        g = g + 1;
        
        SMR = MR{i}.SubModelResult{j};
    
        % create summary table
        colheader = {'SecId','Name','IndGrp','Current BMW(%)','Current ActW(%)','Current Alpha','Hist BMW(%)','Hist ActW(%)','Hist Alpha','ExcRtn(%)','AlphaRtn(%)','SpecRtn(%)','ActContrib(%)'};
        [rowheader, data] = GetStockSummary(SMR, Period);      
        rowheader = regexprep(rowheader, '[_&%$]', '\\$0');
        dummydata = [nan(size(data,1),2), data];
        data = [Num2StrArray(data(:,1),'%10.0f'), Num2StrArray(data(:,2:end),'%10.2f')];
        content = [rowheader, data];
        
        colheader = p.format(colheader, true(size(colheader)), '{\footnotesize %s}');
        content = p.format(content, true(size(content)), '{\footnotesize %s}');
%         content = p.format(content, formatlevel == 1, 'bkcolor', 'ingorange', 'forecolor', 'white', 'bold', '{\footnotesize %s}');
%         content = p.format(content, formatlevel == 2, 'bkcolor', 'inglblue', 'bold', '{\footnotesize %s}');
        content = p.format(content, dummydata < -0.001, 'forecolor', 'red', '{\footnotesize %s}');
        content(1:2:end,1) = strcat('\rowcolor{cone}', content(1:2:end,1));
        content(2:2:end,1) = strcat('\rowcolor{ctwo}', content(2:2:end,1));
        Title = ['\fontsize{5} ',SR.strategyid,', Model: ',SR.modellist.modelname{i},', SubModel: ',MR{i}.submodellist.name{j},'(', SR.(Period).start, ' to ', SR.(Period).end...
            ,')\\ Rtn Contrib: ',num2str(100*SMR.(Period).actRtn, '%10.2f'), '%, Alpha Contrib: ',num2str(100*SMR.(Period).alpha_contrib, '%10.2f'), '%, Specific Contrib: ',num2str(100*SMR.(Period).spec_contrib, '%10.2f'),'%'];
        Title = regexprep(Title, '[_%$&]', '\\$0');
        p.table(Title, colheader, content, 'l l r r r r r r r r r r r', 'landscape');
      
    end
end

%% Combine the report to a pdf

p.run;



end

function [rowheader, data] = GetStockSummary(SMR, Period)
    sdate = SMR.(Period).start;
    edate = SMR.(Period).end;
    
    peridx = find(SMR.TS.actRtn.dates >= datenum(sdate) & SMR.TS.actRtn.dates <= datenum(edate));
    secid = fieldnames(SMR.TS.bmhd,1);
    secinfo = LoadSecInfo(secid,'Name,SubIndustId','','',0);
    secname = secinfo.Name; 
    gics = secinfo.SubIndustId;
    
    secname = cellfun(@(x){x(1:min(16,end))}, secname);

    BMW_Current = fts2mat(SMR.TS.bmhd(peridx(end)))';
    ActW_Current = fts2mat(SMR.TS.actwgt(peridx(end)))';
    Alpha_Current = fts2mat(SMR.TS.alphaScore(peridx(end)))';

    BMW_Hist = SMR.(Period).bmhd';
    ActW_Hist = SMR.(Period).actwgt';
    Alpha_Hist = SMR.(Period).alphaScore';

    ExcRtn = SMR.(Period).fwdret_dm';
    AlphaRtn = SMR.(Period).StockRet_Alpha';
    SpecRtn = SMR.(Period).StockRet_Spec';
    ActContrib = SMR.(Period).stock_contrib';

    rowheader = [secid, secname];
    data = [floor(gics./10^4),100*BMW_Current,100*ActW_Current,Alpha_Current,100*BMW_Hist,100*ActW_Hist,Alpha_Hist,100*ExcRtn,100*AlphaRtn,100*SpecRtn,100*ActContrib];

    delidx = isnan(BMW_Hist);
    data(delidx,:) = [];
    rowheader(delidx,:) = [];
    
    [~, sortidx] = sort(data(:,3),1,'descend'); % rank by current active weight
    data = data(sortidx,:);
    rowheader = rowheader(sortidx,:);
    
end