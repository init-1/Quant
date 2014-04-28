function secStruct = Investigate(StrategyResult, Period, secid)
% this function output a structure which contains the statistics for the
% input stock

if ~iscell(secid)
    secid = {secid};
end

n_m = numel(StrategyResult.ModelResult);
for i = 1:n_m
    n_sm = numel(StrategyResult.ModelResult{i}.SubModelResult);
    for j = 1:n_sm
        SMR = StrategyResult.ModelResult{i}.SubModelResult{j};
        if isempty(SMR)
            continue;
        end
        secidlist = fieldnames(SMR.TS.bmhd,1);
        idx = find(ismember(secidlist, secid));
        if isempty(idx)
            continue;
        end
        
        nfactor = numel(SMR.facinfo.FactorId);
        facname = SMR.facinfo.name;
        
        sdate = SMR.(Period).start;
        edate = SMR.(Period).end;
        peridx = find(SMR.TS.actRtn.dates >= datenum(sdate) & SMR.TS.actRtn.dates <= datenum(edate));
        ExcRtn_ts = SMR.TS.fwdret_dm(peridx, idx);
        AlphaRtn_ts = SMR.TS.StockRet_Alpha(peridx, idx);
        SpecRtn_ts = SMR.TS.StockRet_Spec(peridx, idx);
        BMW_ts = SMR.TS.bmhd(peridx, idx);
        ActW_ts = SMR.TS.actwgt(peridx, idx);
        Alpha_ts = SMR.TS.alphaScore(peridx, idx);
        ActContrib_ts = SMR.TS.stock_contrib(peridx, idx);
        
        SecInfo = LoadSecInfo(secid,'Name','','',0);
        SecName = SecInfo.Name;        
        BMW_Current = fts2mat(SMR.TS.bmhd(peridx(end),idx));
        ActW_Current = fts2mat(SMR.TS.actwgt(peridx(end),idx));
        Alpha_Current = fts2mat(SMR.TS.alphaScore(peridx(end),idx));
        FacScore_Current = reshape(fts2mat(SMR.TS.factorScore(peridx(end),idx,:)), 1, nfactor);
        FacWgt_Current = fts2mat(SMR.TS.facwgt(peridx(end)));
        
        BMW_Hist = SMR.(Period).bmhd(idx);
        ActW_Hist = SMR.(Period).actwgt(idx);
        Alpha_Hist = SMR.(Period).alphaScore(idx);
        FacScore_Hist = reshape(SMR.(Period).factorScore(:,idx,:), 1, nfactor);
        FacWgt_Hist = SMR.(Period).facwgt;
        
        ExcRtn = SMR.(Period).fwdret_dm(idx);
        AlphaRtn = SMR.(Period).StockRet_Alpha(idx);
        SpecRtn = SMR.(Period).StockRet_Spec(idx);
        ActContrib = SMR.(Period).stock_contrib(idx);
        
        %% create report 
        figure;
        row = 4;
        col = 2;
        paperPos = [0, 0, 20, 26];
        set(gcf, 'PaperUnits', 'centimeters', ...
            'PaperType', 'A4', ...
            'PaperPosition', paperPos, ...
            'Units', 'centimeters');

        if(Alpha_ts.dates(end) - Alpha_ts.dates(1)) > 365
            dateformat = 'mmm-yy';
        else
            dateformat = 'dd-mmm';
        end
        
        % alpha
        notes = {['\fontsize{7} Current = ',num2str(100*Alpha_Current,'%10.2f'),'%, Hist. Avg = ',num2str(100*Alpha_Hist,'%10.2f'),'%']};
        tsplot(Alpha_ts, 'title', {'\fontsize{7}\bf Alpha of Stock'},'layout', [row, col]...
            , 'range', {1}, 'dateformat', dateformat, 'notes', notes, 'figure', gcf, 'style', {{'g', 'linewidth', 1.5}}, 'ymin', min(0, nanmin(Alpha_ts)))
%         set(gca, 'fontsize', 6);
        
        % active weight
        notes = {['\fontsize{7} Current = ',num2str(100*ActW_Current,'%10.2f'),'%, Hist. Avg. = ',num2str(100*ActW_Hist,'%10.2f'),'%']};
        tsplot(ActW_ts, 'title', {'\fontsize{7}\bf Active Weight of Stock'},'layout', [row, col]...
            , 'range', {2}, 'dateformat', dateformat, 'notes', notes, 'figure', gcf, 'style', {{'g', 'linewidth', 1.5}}, 'ymin', min(0, nanmin(ActW_ts)))
%         set(gca, 'fontsize', 6);
        
        % cumulative excess return
        notes = {['\fontsize{7} ExcRtn = ',num2str(100*ExcRtn,'%10.2f'),'%, AlphaRtn = ',num2str(100*AlphaRtn,'%10.2f'),'%, SpecRtn = ', num2str(100*SpecRtn,'%10.2f'),'%']};
        tsplot(cumsum([ExcRtn_ts, AlphaRtn_ts, SpecRtn_ts]),'title',{'\fontsize{7}\bf Cumulative Excess Return Decomposition'}...
            ,'layout', [row col],'range',{3},'dateformat', dateformat, 'notes',notes,'figure',gcf,'style',{{'b', 'linewidth', 1.5},{'g', 'linewidth', 1.5},{'r', 'linewidth', 1.5}}...
            ,'legend',strcat('\fontsize{5} ',{'ExcRtn','AlphaRtn','SpecRtn'}),'ymax',max(nanmax(cumsum([ExcRtn_ts, AlphaRtn_ts, SpecRtn_ts]))) + 0.03);
%         set(gca, 'fontsize', 6);
        
        % cumulative active contribution
        notes = {['\fontsize{7} Total Active Contribution = ',num2str(100*cumsum(ActContrib),'%10.2f'),'%']};
        tsplot(cumsum(ActContrib_ts),'title',{'\fontsize{7}\bf Cumulative Active Contribution'}...
            ,'layout', [row col],'range',{4},'dateformat', dateformat, 'notes',notes,'figure',gcf,'style',{{'g', 'linewidth', 1.5}},'ymin',min(nanmin(cumsum(ActContrib_ts)),0));
%         set(gca, 'fontsize', 6);
        
        % factor score
        tsplot((1:numel(FacScore_Current))', [FacScore_Current',FacScore_Hist'], 'title',{'\fontsize{7}\bf Factor Score of Stock'},'legend',strcat('\fontsize{5} ',{'Current','Hist. Avg.'}),'xadjust', true...
            ,'ylabel', '\fontsize{5}', 'xticklabels', strcat('\fontsize{5}',facname), 'drawfun', {@(x,y,varargin)groupDraw(@bar,x,y,varargin{:})}, 'layout', [row col], 'range' ,{[5 6]}...
            , 'ymin', min(0,min(min([FacScore_Current',FacScore_Hist']))), 'ymax', max((max([FacScore_Current',FacScore_Hist'])) + 0.05), 'figure', gcf, 'style', {'',{'flush'}});        
        
        % factor weight
        tsplot((1:numel(FacWgt_Current))', [FacWgt_Current',FacWgt_Hist'], 'title',{'\fontsize{7}\bf Factor Weight'},'legend',strcat('\fontsize{5} ',{'Current','Hist. Avg.'}),'xadjust', true...
            ,'ylabel', '\fontsize{5}', 'xticklabels', strcat('\fontsize{5}',facname), 'drawfun', {@(x,y,varargin)groupDraw(@bar,x,y,varargin{:})}, 'layout', [row col], 'range' ,{[7 8]}...
            , 'ymin', min(0,min(min([FacWgt_Current',FacWgt_Hist']))), 'ymax', max((max([FacWgt_Current',FacWgt_Hist'])) + 0.05), 'figure', gcf, 'style', {'',{'flush'}});        
        
        % title of the report
        axes('Position', [0, 0.98, 1, 0.06], 'visible', 'off');
        desc1 = ['\fontsize{7}\bf Stock: ',secid{:},' (',SecName{:},'), Strategy: ',StrategyResult.strategyid,', Model: ',StrategyResult.modellist.modelname{i},', SubModel: ',StrategyResult.ModelResult{i}.submodellist.name{j},' (', StrategyResult.(Period).start, ' to ', StrategyResult.(Period).end ,')'];
        desc2 = ['\fontsize{7}\bf Excess Return: ',num2str(100*ExcRtn, '%10.2f'),'%, Active Return Contribution: ',num2str(100*ActContrib, '%10.2f'),'%'];
        desc1 = regexprep(desc1, '_', '\\$0');
        desc2 = regexprep(desc2, '_', '\\$0');
        text(0.5,0, desc1, 'HorizontalAlignment', 'center');
        text(0.5,-0.3,desc2, 'HorizontalAlignment', 'center');
        
        saveas(gcf, ['StockReport_',secid{:}], 'pdf');
        close;
        %% end of report
        if ~isempty(idx)
           break;
        end
    end
    if ~isempty(idx)
        break;
    end
end

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