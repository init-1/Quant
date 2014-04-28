function GenUniRegReport(StrategyResult, Period, filename)
% this function generates attribution report using univariate regression approach 
if nargin < 2
    filename = [StrategyResult.strategyid,'_Report'];
end
SR = StrategyResult;
MR = SR.ModelResult;

%% Step 1 - generate summary table
colheader = {'','BMW(%)','Act.ness(%)','NetActW(%)','TC(%)','ActRisk(%)','RiskBudget(%)','ActRtn(%)','AlphaRtn(%)','SpecRtn(%)','Val(%)','Tech(%)','Qual(%)','Sent(%)','Grth(%)'};
rowheader = {SR.strategyid};
structs = {SR.(Period)};
formatlevel = ones(1,numel(colheader));
for i = 1:numel(SR.modellist.modelname)
    rowheader = [rowheader; strcat(' ', SR.modellist.modelname{i}); strcat('  ', MR{i}.submodellist.name)];
    structs = [structs, {MR{i}.(Period)}];
    formatlevel = [formatlevel; 2*ones(1,numel(colheader))];
    for j = 1:numel(MR{i}.submodellist.submodelid)
        if isempty(MR{i}.SubModelResult{j})
            structs = [structs, {''}];
        else
            structs = [structs, {MR{i}.SubModelResult{j}.(Period)}];
        end
        formatlevel = [formatlevel; 3*ones(1,numel(colheader))];
    end
end
rowheader = regexprep(rowheader, '_', '\\$0');
data = GetSummary(structs);
dummydata = [nan(size(data,1),1), data];
content = [rowheader, Num2StrArray(100*data, '% 10.2f')];

%% Step 2 - generate report for individual submodel
stylename = fieldnames(MR{1}.SubModelResult{1}.TS.style_contrib, 1);
lgd1 = {'Avg Weight'};
lgd2 = {'Cum Contribution'};
g = 0;

% report for style performance on strategy + model level
row = 1 + numel(SR.modellist.modelname);
col = 2;
figure;
paperPos = [0, 0, 20, 26];
set(gcf, 'PaperUnits', 'centimeters', ...
    'PaperType', 'A4', ...
    'PaperPosition', paperPos, ...
    'Units', 'centimeters');
g = g+1;
DrawBar([SR.(Period).style_netwgt'], {'Weight'}, stylename, 'Strategy Style Weight', '', 6, row, col, 1);
DrawBar(10000*SR.(Period).style_contrib, lgd2, stylename, 'Strategy Style Contribution (bps)', 'y', 6, row, col, 2);
for i = 1:numel(SR.modellist.modelname)  
    tmp = SR.ModelResult{i}.(Period);
    DrawBar([tmp.style_netwgt'], {'Weight'}, stylename, ['Model Style Weight - ',SR.modellist.modelname{i}] , '', 6, row, col, 2*i+1);
    DrawBar(10000*tmp.style_contrib, lgd2, stylename, ['Model Style Contribution - ',SR.modellist.modelname{i}], 'y', 6, row, col, 2*i+2);
end
axes('Position', [0, 0.98, 1, 0.06], 'visible', 'off');
text(0.5,0, '\bf Strategy / Model Level Report', 'HorizontalAlignment', 'center', 'FontSize', 7);

figid = {['f', num2str(g)]};
saveas(gcf, [figid{g}, '.eps'], 'psc2');
close;

style_abbr = {'V','T','Q','S','G'};           
% plot report for style performance on each sub model level
for i = 1:numel(SR.modellist.modelname)    
    for j = 1:numel(MR{i}.submodellist.name)
        if isempty(MR{i}.SubModelResult{j})
            continue;
        end
        
        figure;
        row = 5;
        col = 2;
        paperPos = [0, 0, 20, 26];
        set(gcf, 'PaperUnits', 'centimeters', ...
            'PaperType', 'A4', ...
            'PaperPosition', paperPos, ...
            'Units', 'centimeters');
        
        g = g + 1;
        tmp = MR{i}.SubModelResult{j}.(Period);
        facname = MR{i}.SubModelResult{j}.facinfo.name;
        facname = cellfun(@(x) {x(1:min(end,13))}, facname); % truncate the factor names which are too long
        DrawBar([tmp.style_netwgt'], {'Weight'}, stylename, 'Style Weight', '', 6, row, col, 1);
        DrawBar(10000*tmp.style_contrib, lgd2, stylename, 'Style Contribution (bps)', 'y', 6, row, col, 2);

        facname = strrep(facname,'_','\_');
        for f = 1:numel(facname)
            facname{f} = ['(',style_abbr{MR{i}.SubModelResult{j}.facinfo.FactorTypeId(f)},')',facname{f}];
        end
        tsplot((1:numel(tmp.facwgt))', tmp.facwgt', 'title',{'\fontsize{7}\bf Factor Weight'}, 'legend',strcat('\fontsize{5} ',{'Weight'}), 'xadjust', true...
            , 'xticklabels', strcat('\fontsize{5}',facname), 'drawfun', {@bar}, 'layout', [row col], 'range' ,{[3 4]}, 'ymin', min(0,min(tmp.facwgt)), 'figure', gcf, 'style', {{'facecolor', 'b'}});        
        set(gca, 'fontsize', 6);
        tsplot((1:numel(tmp.factor_contrib))', 10000*tmp.factor_contrib', 'title',{'\fontsize{7}\bf Factor Contribution (bps)'}, 'legend',strcat('\fontsize{5} ',lgd2), 'xadjust', true...
            , 'xticklabels', strcat('\fontsize{5}',facname), 'drawfun', {@bar}, 'layout', [row col], 'range' ,{[5 6]}, 'ymin', min(0,min(10000*tmp.factor_contrib)), 'figure', gcf, 'style', {{'facecolor', 'y'}});
        set(gca, 'fontsize', 6);
        
        % draw top 10 stock contribution 
        lgd = {'Active wgt', 'Stock rtn(de-mean)', 'Rtn from factor', 'Rtn from specifics'};
        mat = 10000*[tmp.top.actwgt', tmp.top.fwdret_dm', tmp.top.StockRet_Alpha', tmp.top.StockRet_Spec'];
        label = strcat(tmp.top.secid, '(', Num2StrArray(tmp.top.alpha', '%1.2f'), ')');
        title = ['Top 10 Stock Contribution (Total:',num2str(10000*sum(tmp.top.contrib),'%5.0f'),' bps)'];
        DrawBar(mat, lgd, label, title, '', 4, row, col, [7,8]);
        
        % draw bottom 10 stock contribution 
        lgd = {'Active wgt', 'Stock rtn(de-mean)', 'Rtn from factor', 'Rtn from specifics'};
        mat = 10000*[tmp.bot.actwgt', tmp.bot.fwdret_dm', tmp.bot.StockRet_Alpha', tmp.bot.StockRet_Spec'];
        label = strcat(tmp.bot.secid, '(', Num2StrArray(tmp.bot.alpha', '%1.2f'), ')');
        title = ['Bottom 10 Stock Contribution (Total:',num2str(10000*sum(tmp.bot.contrib),'%5.0f'),' bps)'];
        DrawBar(mat, lgd, label, title, '', 4, row, col, [9,10]);        
        
        % title of the report
        axes('Position', [0, 0.98, 1, 0.06], 'visible', 'off');
        desc1 = ['\bf Model: ',SR.modellist.modelname{i},', SubModel: ',MR{i}.submodellist.name{j},'(', SR.(Period).start, ' to ', SR.(Period).end ,')'];
        desc2 = ['\bf Number of Stocks:',num2str(tmp.nsec, '%5.0f'),', Rtn Contrib: ',num2str(100*tmp.actRtn, '%10.2f'), '%, Alpha Contrib: ',num2str(100*tmp.alpha_contrib, '%10.2f'), '%, Specific Contrib: ',num2str(100*tmp.spec_contrib, '%10.2f'),'%'];
        desc1 = regexprep(desc1, '_', '\\$0');
        desc2 = regexprep(desc2, '_', '\\$0');
        text(0.5,0, desc1, 'HorizontalAlignment', 'center', 'FontSize', 7);
        text(0.5,-0.3,desc2, 'HorizontalAlignment', 'center', 'FontSize', 7);
        
        % save file
        figid = [figid; {['f', num2str(g)]}];
        saveas(gcf, [figid{g}, '.eps'], 'psc2');
        close;
    end
end


%% Combine the report to a pdf
p = PDFDoc(filename);
p.writeln('\setlength\tabcolsep{3pt}');
colheader = p.format(colheader, true(size(colheader)), '{\footnotesize %s}');
content = p.format(content, true(size(content)), '{\footnotesize %s}');
content = p.format(content, formatlevel == 1, 'bkcolor', 'ingorange', 'forecolor', 'white', 'bold', '{\footnotesize %s}');
content = p.format(content, formatlevel == 2, 'bkcolor', 'inglblue', 'bold', '{\footnotesize %s}');
content = p.format(content, dummydata < -0.001, 'forecolor', 'red', '{\footnotesize %s}');
content(1:2:end,1) = strcat('\rowcolor{cone}', content(1:2:end,1));
content(2:2:end,1) = strcat('\rowcolor{ctwo}', content(2:2:end,1));
p.table(['Performance Attribution Summary (', SR.(Period).start, ' to ', SR.(Period).end, ')'], colheader, content, 'l c c c c c c c c c c c c c c c c', 'landscape');
% p.figure(figid,'height = 18cm, width = 18cm', '', 1, 1);
p.figure(figid);
p.run;
pdffigs = strcat(figid, '.pdf');
delete(pdffigs{:});

end

function summary = GetSummary(structs)
    summary = [];
    for i = 1:numel(structs)
        stu = structs{i};
        if isempty(stu)
            summary = [summary; nan(1,size(summary,2))];
        else
            summary = [summary; [stu.totalbmwgt, stu.activeness, stu.netactwgt, stu.TC, stu.actRisk, sqrt(stu.variance), stu.actRtn, stu.alpha_contrib, stu.spec_contrib, stu.style_contrib]];
        end
    end
end

function DrawBar(mat, lgd, label, bartitle, color, fontsize, row, col, pos)
    subplot(row, col, pos);
    bar(mat, color);
    set(gca, 'ylim', [min(0,min(min(mat))),inf]);
    grid on;
    title(['\fontsize{7}\bf ',bartitle]);
    set(gca, 'XTickLabel', label, 'fontsize', fontsize);
%     legend(lgd, 'Location', 'northeast','fontsize', 5);               
    legend(lgd, 'fontsize', fontsize);               
end

function groupDraw(fun, x, y, varargin)
    persistent x_  y_ style_
    if isempty(x_)
        x_ = x;
    else
        FTSASSERT(isequal(x,x_));
    end
    
    y_ = [y_ y];
    style_ = varargin;
    if ~isempty(style_) && strcmpi(style_{end}, 'flush')
        fun(x_, y_, style_{1:end-1});
        x_ = [];
        y_ = [];
        style_ = [];
    end
end
