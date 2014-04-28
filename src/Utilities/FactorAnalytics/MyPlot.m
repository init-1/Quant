% this is a class which only has static method that are plot functions used in CalcStatistics
classdef MyPlot
    
properties
end
   
methods 
end

methods (Static)   
    function fig = PlotCoverage(row, col, pos, fig, mean_ac, mean_coverage, mean_nonezero, autocorr, coverage, nonezero)
        % plot - autocorrelation & coverage
        [autocorr, coverage, nonezero] = MyPlot.NaNtoZero(autocorr, coverage, nonezero);
        lgd = cell(1,3); 
        lgd{1} = ['Auto Corr, average =', num2str(mean_ac, '%3.2f')];
        lgd{2} = ['Coverage, average =', num2str(mean_coverage, '%3.2f')];
        lgd{3} = ['Non-zero, average =', num2str(mean_nonezero, '%3.2f')];
        fig = tsplot([autocorr, coverage, nonezero], 'title', {'Auto-Correlation & Coverage'}...
            ,'style',{{'b', 'linewidth', 1.5},{'r','linewidth',1.5}, {'g', 'linewidth',1.5}},'ymax', 1.2 ...
            , 'legend', {{lgd, 'location','northwest', 'fontsize', 5}}, 'layout', [row, col], 'range', {pos}, 'figure', fig);
    end    

    function fig = PlotCumRtn(row, col, pos, fig, LS, neutralstyle, IRLS)
        % plot - cumulative factor portfolio return
        fts = ftsmovsum([LS{:}], inf, 1);
        ymax = max(max(fts2mat(fts))) + 0.2;
        lgd = neutralstyle;
        for m = 1:numel(neutralstyle)
            lgd{m} = [neutralstyle{m}, ': IR = ',num2str(IRLS(m), '%3.2f')];
        end
        fts = MyPlot.NaNtoZero(fts);
        tsplot(fts, 'title', {'Cumulative Factor Return Neutralized on Styles'}...
            , 'style', {{'-b', 'linewidth', 1.5},{'-g', 'linewidth', 1.5},{'-r', 'linewidth', 1.5},{'-k', 'linewidth', 1.5},{'-y', 'linewidth', 1.5}}...
            , 'ymax', ymax ...
            , 'legend', {{lgd,'location','northwest','fontsize', 5}}, 'layout', [row, col], 'range', {pos}, 'figure', fig);
            
            
    end
    
    function PlotICIR(row, col, pos, fig, neutralstyle, mean_IC, IRIC, IC)
        fts = ftsmovavg([IC{:}],6,1);
        ymax = max(max(fts2mat(fts))) + 0.2;
        startidx = find(any(~isnan(fts2mat(fts)),2),1,'first');
        fts(startidx:min(startidx+4, end),:) = NaN;
        lgd = neutralstyle;
        for m = 1:numel(neutralstyle)
            lgd{m} = [neutralstyle{m}, ': IC=',num2str(mean_IC(m)*100, '%3.1f'), '% IR(IC)=',num2str(IRIC(m), '%3.2f')];
        end
        fts = MyPlot.NaNtoZero(fts);
        tsplot(fts, 'title', {'Six Period Rolling IC Neutralized on Styles'}...
            , 'style', {{'-b', 'linewidth', 1.5},{'-g', 'linewidth', 1.5},{'-r', 'linewidth', 1.5},{'-k', 'linewidth', 1.5},{'-y', 'linewidth', 1.5}}...
            , 'ymax', ymax ...
            , 'legend', {{lgd,'location','northwest','fontsize', 5}}, 'layout', [row, col], 'range', {pos}, 'figure', fig);
    end
    
    function fig = PlotStat(row, col, pos, fig, cs_median, toptile, bottile)
        % plot - descriptive statistics
        fts = [cs_median, toptile, bottile];
        lgd = {'median','80 pct','20 pct'};
        fts = MyPlot.NaNtoZero(fts);
        tsplot(fts, 'title', {'Cross Sectional Raw Factor Statistics'}...
            , 'style', {{'-b', 'linewidth', 1.5},{'-g', 'linewidth', 1.5},{'-r', 'linewidth', 1.5},{'-k', 'linewidth', 1.5}}...
            , 'legend', {{lgd,'location','northwest','fontsize', 5}}, 'layout', [row, col], 'range', {pos}, 'figure', fig);
    end

    

%     function PlotICIR(row, col, pos, neutralstyle, mean_IC, IRIC)
%         % plot - IC by neutralized style
%         subplot(row, col, pos);
%         lgd = neutralstyle;
%         mat = [mean_IC*100; IRIC];
%         for m = 1:numel(neutralstyle)
%             lgd{m} = [neutralstyle{m}, ': IC=',num2str(mean_IC(m)*100, '%3.1f'), '% IR(IC)=',num2str(IRIC(m), '%3.2f')];
%         end
%         bar(mat);
%         title('\bf Factor IC Neutralized on Styles');
%         set(gca, 'XTickLabel', {'Mean IC(%)','Ann. IR(IC)'}, 'fontsize', 6.5);
%         legend(lgd, 'Location', 'northeast','fontsize', 6);               
%     end

%                 % plot - Factor Return By Day
%                 mat = cell2mat(cellfun(@(c) {nanmean(c)}, LSByDay))*sqrt(252)*100;
%                 subplot(4,2,4);
%                 bar(mat);
%                 title('\bf Ann. Factor Return(%) on Nth Day after Rebalancing');
%                 legend(neutralstyle,'location','northeast','fontsize', 6);
    function PlotByGICS(row, col, pos, IRICByGICS, numByGICS, neutralstyle)
        % plot - Factor Return By Day                
        mat = IRICByGICS;
        mat = MyPlot.NaNtoZero(mat);
        xLabel = {'ENE','MAT','IND','CDI','CST','HEA','FIN','IT','TEL','UTI'};
    %     for i = 1:numel(xLabel), xLabel{i} = [xLabel{i},'(',num2str(numByGICS(i),'%3.0f'),')']; end
        subplot(row, col, pos);
        bar(mat);
        title('\bf IR of IC in Each Sector');
        set(gca, 'XTickLabel', xLabel, 'fontsize', 5);
        legend(neutralstyle,'fontsize', 5);
    end

    function PlotByCtry(row, col, pos, IRICByCtry, numByCtry, neutralstyle, uniqCtry)
        % plot - Factor Return By Day                
        mat = IRICByCtry;
        mat = MyPlot.NaNtoZero(mat);
        xLabel = reshape(uniqCtry, 1, numel(uniqCtry));
        xLabel = [xLabel, repmat({''},1,size(IRICByCtry,1)-numel(xLabel))];
        %     for i = 1:numel(xLabel), xLabel{i} = [xLabel{i},'(',num2str(numByGICS(i),'%3.0f'),')']; end
        subplot(row, col, pos);
        bar(mat);
        title('\bf IR of IC in Each Country');
        set(gca, 'XTickLabel', xLabel, 'fontsize', 5);
        legend(neutralstyle,'fontsize', 5);        
    end
    
    function PlotByRegime(row, col, pos, regimeLSIR, regimename, neutralstyle)
        % plot - Factor Return By Regime
        mat = regimeLSIR;
        mat = MyPlot.NaNtoZero(mat);
        subplot(row, col, pos);
        bar(mat);
        title('\bf Ann. Factor Return IR in Different VIX Regime');
        set(gca, 'XTickLabel', regimename, 'fontsize', 5);
        legend(neutralstyle,'location','northeast','fontsize', 5);
    end

    function PlotLongShort(row, col, pos, mean_Long, mean_Short, mean_LS, neutralstyle)
        % plot - Factor Return by Long/Short Side
        mat = [mean_Long; mean_Short; mean_LS];
        mat = MyPlot.NaNtoZero(mat);
        subplot(row, col, pos);
        bar(mat);
        title('\bf Ann. Factor Return from Long/Short Side');
        set(gca, 'XTickLabel', {'+Long-BM','-Short+BM', 'Long-Short'}, 'fontsize', 5);
        legend(neutralstyle,'location','northeast','fontsize', 5);                                
    end

    function PlotStockRtn(row, col, pos, ContribByRtn, neutralstyle)
        % plot - Stock Return Contribution Sorted by Itself
        mat = ContribByRtn;
        mat = MyPlot.NaNtoZero(mat);
        subplot(row, col, pos);
        bar(mat);
        title('\bf Ann. Stock Contribution to Factor Return');
        legend(neutralstyle,'location','northwest','fontsize', 5);               
    end

    function PlotRtnByMcap(row, col, pos, ShortRtnByMcap, neutralstyle)
        % plot - Short Side Return Contribution Sorted by MktCap
        mat = ShortRtnByMcap;
        mat = MyPlot.NaNtoZero(mat);
        Xlabel = repmat({''},1,size(mat,1));
        Xlabel{1} = 'Small'; Xlabel{end} = 'Large';
        subplot(row, col, pos);
        bar(mat);
        title('\bf Ann. Short-Side Return Sorted by MktCap');
        set(gca, 'XTickLabel', Xlabel, 'fontsize', 5);
        legend(neutralstyle,'location','northwest','fontsize', 5);  
    end

    function PlotScoreByMcap(row, col, pos, ShortScoreByMcap, neutralstyle)
        % plot - Short Side Factor Score Sorted by MCap
        mat = ShortScoreByMcap;
        mat = MyPlot.NaNtoZero(mat);
        Xlabel = repmat({''},1,size(mat,1));
        Xlabel{1} = 'Small'; Xlabel{end} = 'Large';
        subplot(row, col, pos);
        bar(mat);
        title('\bf Short-Side Factor Score Sorted by MktCap');
        set(gca, 'XTickLabel', Xlabel, 'fontsize', 5);
        legend(neutralstyle,'location','northwest','fontsize', 5);   
    end

    function PlotRtnByCost(row, col, pos, ShortRtnByBrCost, neutralstyle)
        % plot - Short Side Return Contribution Sorted by BrCost
        mat = ShortRtnByBrCost;
        mat = MyPlot.NaNtoZero(mat);
        Xlabel = repmat({''},1,size(mat,1));
        Xlabel{1} = 'Expensive'; Xlabel{end} = 'Cheap';
        subplot(row, col, pos);
        bar(mat);
        title('\bf Ann. Short-Side Return Sorted by BrCost');
        set(gca, 'XTickLabel', Xlabel, 'fontsize', 5);
        legend(neutralstyle,'location','northwest','fontsize', 5);                  
    end

    function PlotScoreByCost(row, col, pos, ShortScoreByBrCost, neutralstyle)
        % plot 8 - Short Side Factor Score Sorted by BrCost
        mat = ShortScoreByBrCost;
        mat = MyPlot.NaNtoZero(mat);
        Xlabel = repmat({''},1,size(mat,1));
        Xlabel{1} = 'Expensive'; Xlabel{end} = 'Cheap';
        subplot(row, col, pos);
        bar(mat);
        title('\bf Short-Side Factor Score Sorted by BrCost');
        set(gca, 'XTickLabel', Xlabel, 'fontsize', 5);
        legend(neutralstyle,'location','northwest','fontsize', 5);   
    end

    function PlotRtnByLiq(row, col, pos, FacPFRtnByAdv, neutralstyle)
       % plot - FactorPF Return Sorted by Liquidity
        mat = FacPFRtnByAdv;
        mat = MyPlot.NaNtoZero(mat);
        Xlabel = repmat({''},1,size(mat,1));
        Xlabel{1} = 'Illiquid'; Xlabel{end} = 'Liquid';
        subplot(row, col, pos);
        bar(mat);
        title('\bf Ann. FactorPF Return Sorted by Liquidity');
        set(gca, 'XTickLabel', Xlabel, 'fontsize', 5);
        legend(neutralstyle,'location','northwest','fontsize', 5);        
    end

    function PlotScoreByLiq(row, col, pos, FacPFScoreByAdv, neutralstyle)
        % plot - abs of FactorPF Score Sorted by Liquidity
        mat = FacPFScoreByAdv;
        mat = MyPlot.NaNtoZero(mat);
        Xlabel = repmat({''},1,size(mat,1));
        Xlabel{1} = 'Illiquid'; Xlabel{end} = 'Liquid';
        subplot(row, col, pos);
        bar(mat);
        title('\bf FactorPF Score Sorted by Liquidity');
        set(gca, 'XTickLabel', Xlabel, 'fontsize', 5);
        legend(neutralstyle,'location','northwest','fontsize', 5);         
    end
    
    function PlotRtnByQuintile(row, col, pos, FacPFRtnByQunitile, neutralstyle)
       % plot - FactorPF Return Return By Quintiles
        mat = FacPFRtnByQunitile;
        mat = MyPlot.NaNtoZero(mat);
        Xlabel = repmat({''},1,size(mat,1));
        Xlabel{1} = 'Q1'; Xlabel{end} = 'Qn';
        subplot(row, col, pos);
        bar(mat);
        title('\bf Ann. Eq. Weighted Return By Quintiles');
        set(gca, 'XTickLabel', Xlabel, 'fontsize', 5);
        legend(neutralstyle,'location','northwest','fontsize', 5);        
    end
    
    function varargout = NaNtoZero(varargin)
        % set nan observations to zero
        varargout = varargin;
        for i = 1:numel(varargin)
            varargout{i}(isnan(varargout{i})) = 0;
        end
    end
    
end % of methods

end % of class