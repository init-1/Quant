classdef Report < handle
    properties (Constant)        
        FIG_PAGE_FMT = '-P%2.2d.pdf';
    end
    
    properties (Access = private)        
        dates
        dataset
        rebal
        
        summary
        pffinal
        trd
        totalPrice
        strategy
        vios
        
        repFileName = '';
        figCounter = 0;
        figLayout = false(2,4);  % actually 4,2, factilicate column order matrix
        figPage = 0;
        figColorMap
        
        ROLLING_WINDOW = -63;
    end
   
    methods
       function o = Report(dataset, rebal, results, fname, rebaldates, str)
            if nargin < 5, rebaldates = dataset.dates; end

            o.dataset = dataset;
            o.rebal = rebal;
            o.dates = rebaldates;
            if exist('str','var')
                o.strategy = str;
            else
                o.strategy = [];
            end

            T = length(keys(results));
            ret = cell2mat(values(results));
            o.summary = cat(1, ret.summary);  % summary now an full-period xts 
            o.vios = Report.getViolationSummary(results);
            
            final = {ret.pffinal};
            [final{:}] = alignfields(final{:}, 'union', 1);
            o.pffinal = cat(1, final{:});
            
            trades = {ret.trd};
            [trades{:}] = alignfields(trades{:}, 'union', 1);
            o.trd = cat(1, trades{:});
            
            o.repFileName = fname;
            o.figColorMap = brighten(copper(T), -0.1);
            
            o.totalPrice = LoadQSSecTS(setdiff(fieldnames(o.pffinal,1,1), 'CASH'), 1052, 0, ...
                datestr(rebaldates(1)-100,'yyyy-mm-dd'), datestr(rebaldates(end)+100,'yyyy-mm-dd'));
            o.totalPrice = backfill(o.totalPrice,14,'entry');
            o.totalPrice = padfield(o.totalPrice, fieldnames(o.pffinal,1,1), NaN);
        end
       
        function stat = run(o)
            set(0, 'DefaultFigureVisible', 'off');
            if size(o.pffinal,1) > 1
                statDaily  = onDailyReturn(o);
                [statPeriod, rtn, weight, alpha] = onPeriodReturns(o);
                w = weight(:,:,'pfweight');
                if ~isempty(w(w < 0))
                    isshort = 1;
                else
                    isshort = 0;
                end
                statExpRisk = expectedRisk(o);

                stat.daily = statDaily;
                stat.period = statPeriod;
                stat.exprisk = statExpRisk;
            else
                stat = [];
            end
            
            if size(o.pffinal,1) < 12
                TRACE.Warn('Report will not generated since number of backtest periods less than 12\n');
                return;
            end
            
            cidx = round(1:size(o.figColorMap,1)/5:size(o.figColorMap,1));
            cb_h = 0.00618;
            cb_ygap = 0.0045;
            pThick1 = {'LineWidth', 1, 'color', o.figColorMap(cidx(2),:)};
            pThick2 = {'LineWidth', 1, 'color', o.figColorMap(cidx(3),:)};
            pThick3 = {'LineWidth', 1, 'color', o.figColorMap(cidx(4),:)};
            pThick4 = {'LineWidth', 1, 'color', o.figColorMap(cidx(5),:)};
            pThin   = {'LineWidth', 0.5, 'color', o.figColorMap(cidx(3),:)};
            bThin   = {'BarWidth', 0.28, 'facecolor', o.figColorMap(cidx(3),:), 'edgecolor', o.figColorMap(cidx(3),:)};
            aLight  = {'facecolor', o.figColorMap(cidx(5),:)};
            
            grpArea = @(x,y,varargin)groupDraw(@area,x,y,varargin{:});
            grpBar  = @(x,y,varargin)groupDraw(@bar,x,y,varargin{:});
            bFlushed = {'flush'}; %{'stacked','BarWidth',0.58,'flush'};
            
            r = uniftsfun(statDaily.return(:,{'Portfolio' 'Benchmark'})+1, @cumprod);
            ra = exp(cumsum(log(1+statDaily.return(:,'Active'))))-1;
            o.draw(1, [statDaily.return(:,'Active')*100 bsxfun(@minus,r(:,1),r(:,2))*100 ra*100] ...
                , 'title', 'Active Daily Return' ...
                , 'drawfun', {@bar @plot @plot} ...
                , 'group', [1 -1 -1] ...
                , 'style', {bThin pThick4 pThick1} ...
                , 'ylabel', {['\color[rgb]{' num2str(o.figColorMap(cidx(2),:)) '}Return(%)'] ...
                             ['\color[rgb]{' num2str(o.figColorMap(cidx(5),:)) '}Cumulative(%)']} ...
                , 'notes', ['Ann.Return: ' num2str(252*100*nanmean(statDaily.return(:,'Active')),'%.2f') '%, Ann.Vol: ' num2str(sqrt(252)*100*nanstd(statDaily.return(:,'Active')),'%.2f') '%, MaxDD: ' num2str(100*min(fts2mat((1+ra)/ftsmovfun(1+ra,Inf,@max)-1)),'%.2f') '%']);
            h = get(gca, 'yLabel');
            xlim = get(gca, 'xlim');
            posn = get(h, 'Position');
            posn(1) = posn(1)+(xlim(2)-xlim(1))*0.06;
            set(h, 'Position', posn);
%             h = findobj('Type', 'axes', 'YAxisLocation', 'right', 'xLim', xlim);
%             h = get(h(1), 'yLabel');
%             posn = get(h, 'Position');
%             posn(1) = posn(1)-(xlim(2)-xlim(1))*0.07;
%             set(h, 'Position', posn);
            
            o.draw(1, [statDaily.return(:,'Portfolio')*100 (r(:,'Portfolio')-1)*100] ...
                , 'title', 'Portfolio Daily Return' ...
                , 'drawfun', {@bar @plot} ...
                , 'group', [1 -1] ...
                , 'style', {bThin pThick4} ...
                , 'ylabel', {['\color[rgb]{' num2str(o.figColorMap(cidx(2),:)) '}Return(%)'] ...
                             ['\color[rgb]{' num2str(o.figColorMap(cidx(5),:)) '}Cumulative(%)']} ...
                , 'notes', ['Ann. Return: ' num2str(252*100*nanmean(statDaily.return(:,'Portfolio')),'%.2f') '%, Ann.Vol: ' num2str(sqrt(252)*100*nanstd(statDaily.return(:,'Portfolio')),'%.2f') '% , maxDD: ' num2str(100*min(fts2mat(r(:,'Portfolio')/ftsmovfun(r(:,'Portfolio'),Inf,@max)-1)),'%.2f') '%']);
            h = get(gca, 'yLabel');
            xlim = get(gca, 'xlim');
            posn = get(h, 'Position');
            posn(1) = posn(1)+(xlim(2)-xlim(1))*0.08;
            set(h, 'Position', posn);
            hs = findobj('Type', 'axes', 'YAxisLocation', 'right', 'xLim', xlim);
            for i = 1:length(hs)
                h = get(hs(i), 'yLabel');
                posn = get(h, 'Position');
                posn(1) = posn(1)-(xlim(2)-xlim(1))*0.07;
                set(h, 'Position', posn);
            end
            
            switch statDaily.estfreq
                case 5
                    freqtitle = '5-Day Rolling ';
                    o.ROLLING_WINDOW = -22;
                case 90
                    freqtitle = '3-Month Rolling ';
                    o.ROLLING_WINDOW = -22;
                case 252
                    freqtitle = '1-Year Rolling ';
            end
            o.draw(1, statDaily.annualIR ...
                , 'title', [freqtitle 'Information Ratio'] ...
                , 'drawfun', {@plot} ...
                , 'hornlineposn', nanmean(statDaily.annualIR) ...
                , 'style', {pThin} ...
                , 'notes', ['Overall IR: ' num2str(statDaily.IR,'%.2f') ', Min IR: ' num2str(nanmin(statDaily.annualIR),'%.2f') ', Max IR:' num2str(nanmax(statDaily.annualIR),'%.2f')]);

            o.draw(1, statDaily.annualSR ...
                , 'title', [freqtitle 'Sharpe Ratio'] ...
                , 'drawfun', {@plot} ...
                , 'hornlineposn', nanmean(statDaily.annualSR) ...                
                , 'style', {pThin} ...
                , 'notes', ['Overall SR: ' num2str(nanmean(statDaily.annualSR),'%.2f') ', Min SR: ' num2str(nanmin(statDaily.annualSR),'%.2f') ', Max SR:' num2str(nanmax(statDaily.annualSR),'%.2f')]);

            o.draw(1, o.summary(:,{'shortcount' 'longcount'},'final') ...
                , 'title', 'Long/Short Counts' ...
                , 'drawfun', {grpArea} ...
                , 'ymin', 0 ...
                , 'ymax',  nanmax(o.summary(:,'count','final')) ...
                , 'style', {{},bFlushed} ...
                , 'legend', {'Short' 'Long'});
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                , ['\fontsize{8}\bf\color[rgb]{1 .4 0}mean(Count): ' num2str(nanmean(o.summary(:,'count','final')),'%.0f')] ...
                , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            
            o.draw(1, uniftsfun(o.summary(:,{'tradecount' 'buycount' 'sellcount'},'final'), @(x)[x(:,[2 3]) x(:,1)-x(:,2)-x(:,3)], {'buycount' 'sellcount' 'residual'})...
                , 'title', 'Buy/Sell Counts' ...
                , 'drawfun', {grpArea} ...
                , 'ymin',  0 ...
                , 'ymax',  nanmax(o.summary(:,'tradecount','final')) ...
                , 'style', {{} {} bFlushed} ...
                , 'legend', {'Buy','Sell','Res'});
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                , ['\fontsize{8}\bf\color[rgb]{1 .4 0}mean(Trades): ' num2str(nanmean(o.summary(:,'tradecount','final')),'%.0f')] ...
                , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            
            o.draw(1, o.summary(2:end,{'buytopct' 'selltopct'},'final') ...
                , 'title', 'Turnover PCT' ...
                , 'drawfun', {grpArea} ...
                , 'ymin',  0 ...
                , 'ymax',  nanmax(o.summary(2:end,'turnoverpct','final')) ...
                , 'style', {{},bFlushed} ...
                , 'legend', {'Buy','Sell'});
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                , ['\fontsize{8}\bf\color[rgb]{1 .4 0}mean(Turnover): ' num2str(100*nanmean(o.summary(2:end,'turnoverpct','final')),'%.2f') '%'] ...
                , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');

            if ~isequal(o.summary(:,'tcost_est','final'),o.summary(:,'tcost','final'))
                y = [10000*bsxfun(@rdivide, o.summary(:,{'arrival','marketimpact','vwapspread','commission','fee'},'final'), o.summary(:,'turnover','final')) 10000*mean(diff(o.dates))/252*bsxfun(@rdivide, o.summary(:,'borrowcost_ann','final'), o.summary(:,'turnover','final'))];
%                 y = y(2:end,:);
                yp = y;
                yp(yp <= 0) = 0;
                ym = fts2mat(y);
                ym(ym > 0) = 0;
                o.draw(1, yp ...
                    , 'title', 'TCost/Turnover (bps)' ...
                    , 'xadjust', true ...
                    , 'ymin', min(nansum(ym,2))-5 ...
                    , 'ymax', max(nansum(yp,2))+5 ...
                    , 'drawfun', {grpBar}, 'style', {{} {} {} {} {} {'stacked', 'barwidth', min(0.8,size(y,1)./16), 'edgecolor', 'none', 'flush'}});
                hold on;
                bar(ym, 'stacked', 'barwidth', min(0.8,size(y,1)./16), 'edgecolor', 'none');
                hold on;
                ymean = nansum(fts2mat(y),2);
                ymean(ymean <= 0) = 0;
                bar(ymean, 'barwidth', min(0.2,size(y,1)./24), 'edgecolor', 'none', 'facecolor', [1 0 0]);
                hold on;
                ymean = nansum(fts2mat(y),2);
                ymean(ymean > 0) = 0;
                bar(ymean, 'barwidth', min(0.2,size(y,1)./24), 'edgecolor', 'none', 'facecolor', [0 1 0]);
                
                simpleLegend({'Arrival','Impact','Vwap','Comms','Fees','Borrow'},o.figColorMap);                    
                
                xlim = get(gca, 'XLim');
                ylim = get(gca, 'YLim');
                text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                    , ['\fontsize{8}\bf\color[rgb]{1 .4 0}mean(Cost): ' num2str(nanmean(nansum(fts2mat(y),2)),'%.2f') 'bps'] ...
                    , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            else
                o.draw(1, 10000*bsxfun(@rdivide, o.summary(:,'tcost','final'), o.summary(:,'turnover','final')) ...
                    , 'title', 'TCost/Turnover (bps)' ...
                    , 'drawfun', {@bar} ...
                    , 'xadjust', true ...
                    , 'style', {bThin});
            end

            actness = cssum(abs(weight(:,:,'actweight'))) / 2;
            o.draw(1, actness ...  % activeness
                , 'title', 'Activeness' ...
                , 'drawfun', {@bar} ...
                , 'xadjust', true ...
                , 'style', {bThin} ...
                , 'notes', ['Avg Activeness: ' num2str(100*nanmean(actness),'%.2f') '%, Min: ' num2str(100*nanmin(actness),'%.2f') '%, Max:' num2str(100*nanmax(actness),'%.2f') '%']);
                
            actness = cssum(abs(weight(:,:,'pfweight'))) / 2;
            o.draw(1, actness ...  % activeness
                , 'title', 'Activeness (Portfolio)' ...
                , 'drawfun', {@bar} ...
                , 'xadjust', true ...
                , 'style', {bThin} ...
                , 'notes', ['Avg Activeness: ' num2str(100*nanmean(actness),'%.2f') '%, Min: ' num2str(100*nanmin(actness),'%.2f') '%, Max:' num2str(100*nanmax(actness),'%.2f') '%']);
            
            rho_alpha = alphaAutoCorr(o, 12);
            o.draw(1, rho_alpha(:,1) ...
                , 'title', 'Alpha Autocorrelation' ...
                , 'drawfun', {@bar} ...
                , 'style', {bThin} ...
                , 'ymax', 1 ...
                , 'ymin', 0 ...
                , 'notes', ['Avg Autocorrelation: ' num2str(nanmean(rho_alpha(:,1))*100,'%.2f') '%']);

            o.draw(1, statPeriod.omega(:,1), statPeriod.omega(:,2) ...
                , 'xticklabels', num2str(statPeriod.omega(:,1)*100,'%.2f') ...
                , 'title', 'Omega Ratio' ...
                , 'drawfun', {@semilogy} ...
                , 'style', {pThick1});
            h = xlabel('Return (%)');
            posn = get(h, 'position');
            ylim = get(gca, 'ylim');
            posn(2) = posn(2)-(ylim(2)-ylim(1))*0.0001;
            set(h, 'position', posn);
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                , ['\fontsize{8}\bf\color[rgb]{1 .4 0}Omega Excess: ' num2str(max(statPeriod.omega(:,2)),'%.4f')] ...
                , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            
            ymin = min(nanmin(statPeriod.ic), nanmin(statPeriod.impic));
            ymax = max(nanmax(statPeriod.ic), nanmax(statPeriod.impic));
            o.draw(1, statPeriod.ic ...
                , 'title', 'Information Coefficient (Signal)' ...
                , 'drawfun', {@bar} ...
                , 'style', {bThin} ...
                , 'ymin', ymin, 'ymax', ymax ...
                , 'xadjust', true ...
                , 'notes', ['Avg IC: ' num2str(100*nanmean(statPeriod.ic),'%.2f') '%, Min IC: ' num2str(100*nanmin(statPeriod.ic),'%.2f') '%, Max IC: ' num2str(100*nanmax(statPeriod.ic),'%.2f') '%']);
            
            if isshort, actstr = 'Port'; else actstr = 'Act'; end
            o.draw(1, statPeriod.impic ...
                , 'title', ['Information Coefficient (' actstr 'Wgt)'] ...
                , 'drawfun', {@bar} ...
                , 'style', {bThin} ...
                , 'ymin', ymin, 'ymax', ymax ...
                , 'xadjust', true ...
                , 'notes', ['Avg IC: ' num2str(100*nanmean(statPeriod.impic),'%.2f') '%, Min IC: ' num2str(100*nanmin(statPeriod.impic),'%.2f') '%, Max IC: ' num2str(100*nanmax(statPeriod.impic),'%.2f') '%']);
            
            ymin = min(nanmin(statPeriod.impic-statPeriod.ic));
            ymax = max(nanmax(statPeriod.impic-statPeriod.ic));
            o.draw(1, statPeriod.impic-statPeriod.ic ...
                , 'title', ['IC Spread (' actstr 'Wgt - Signal)'] ...
                , 'drawfun', {@bar} ...
                , 'style', {bThin} ...
                , 'ymin', ymin, 'ymax', ymax ...
                , 'xadjust', true ...
                , 'notes', ['Avg Spread: ' num2str(100*nanmean(statPeriod.impic-statPeriod.ic),'%.2f') '%, Min Spread: ' num2str(100*nanmin(statPeriod.impic-statPeriod.ic),'%.2f') '%, Max Spread: ' num2str(100*nanmax(statPeriod.impic-statPeriod.ic),'%.2f') '%']);
            
            o.draw(1, o.summary(:,{'axiomaTC' 'linearTC'},'final') ...
                , 'title', 'Transfer Coefficient' ...
                , 'drawfun', {@plot} ...
                , 'style', {pThick1, pThick4} ...
                , 'ymin', 0, 'ymax', 1 ...
                , 'legend', {'AXIOMA','Linear'});
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                , ['\fontsize{8}\bf\color[rgb]{1 .4 0}mean(TC): ' num2str(nanmean(o.summary(:,'linearTC','final')),'%.4f')] ...
                , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            
            o.draw(1, cumsum(statPeriod.return_attribution(:,{'Long' 'Alpha Long'})) ...
                , 'title', 'Long-Side Active Return Attribution' ...
                , 'drawfun', {@plot} ...
                , 'style', {pThick1, pThick4} ...
                , 'legend', {'Optimized PF' 'Alpha PF'});
            
            o.draw(1, cumsum(statPeriod.return_attribution(:,{'Short' 'Alpha Short'})) ...
                , 'title', 'Short-Side Active Return Attribution' ...
                , 'drawfun', {@plot} ...
                , 'style', {pThick1, pThick4} ...
                , 'legend', {'Optimized PF' 'Alpha PF'});
            
            o.draw(1, cumsum(statPeriod.return_attribution(:,{'PF Long' 'Alpha PF Long'})) ...
                , 'title', 'Long-Side Return Attribution' ...
                , 'drawfun', {@plot} ...
                , 'style', {pThick1, pThick4} ...
                , 'legend', {'Optimized PF' 'Alpha PF'});
            
            o.draw(1, cumsum(statPeriod.return_attribution(:,{'PF Short' 'Alpha PF Short'})) ...
                , 'title', 'Short-Side Return Attribution' ...
                , 'drawfun', {@plot} ...
                , 'style', {pThick1, pThick4} ...
                , 'legend', {'Optimized PF' 'Alpha PF'});

            o.draw(1, o.summary(:,{'activerisk' 'actfactorrisk' 'actspecrisk'},'final') ...
                , 'title', 'Active Risk' ...
                , 'drawfun', {@plot} ...
                , 'ymin',  0 ...
                , 'ymax',  nanmax(o.summary(:,'activerisk','final'))*1.2 ...
                , 'style', {pThick1 pThick2 pThick4} ...
                , 'legend', {'Total' 'Factor','Specific'});
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-(ylim(2)-ylim(1))*0.01 ...
                , '\fontsize{8}\bf\color[rgb]{1 .4 0}Total^2=Factor^2+Specific^2' ...
                , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            
            o.draw(1, o.summary(:,{'totalrisk_bm' 'totalrisk_pf' 'specrisk', 'factorrisk'},'final') ...
                , 'title', 'Total Risk' ...
                , 'drawfun', {@plot} ...
                , 'ymin',  0 ...
                , 'ymax',  nanmax(o.summary(:,'totalrisk_pf','final'))*1.2 ...
                , 'style', {pThick1 pThick2 pThick3 pThick4} ...
                , 'legend', {'BM' 'PF' '\epsilon' 'Factor'});
            xlim = get(gca, 'XLim');
            ylim = get(gca, 'YLim');
            text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-(ylim(2)-ylim(1))*0.01 ...
                , '\fontsize{8}\bf\color[rgb]{1 .4 0}Total^2=Factor^2+Specific^2' ...
                , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');

            [realRisk, expRisk] = aligndates(statDaily.realisedRisk, statExpRisk.expectedRisk, o.dates);
            for risktype = {'Active' 'Portfolio'}
                o.draw(1, [expRisk(:,risktype) realRisk(:,risktype)] ...
                    , 'title', [risktype{:} ' Risk: Predicted vs Realised'] ...
                    , 'drawfun', {@area @bar} ...
                    , 'style', {aLight bThin} ...
                    , 'legend', {'Predicted','Realized'} ...
                    , 'xadjust', true ...
                    , 'ymin', 0);
                xlim = get(gca, 'XLim');
                ylim = get(gca, 'YLim');
                text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                    , ['\fontsize{8}\bf\color[rgb]{1 .4 0}mean(Realized): ' num2str(100*nanmean(realRisk(:,risktype)),'%.2f') '%'] ...
                    , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            end
            
            [realBeta, expBeta] = aligndates(statDaily.realisedBeta, statExpRisk.expectedBeta, o.dates);
            for risktype = {'Active' 'Portfolio'}
                o.draw(1, [expBeta(1:end-1,risktype), realBeta(1:end-1,risktype)] ... % last period yet to be realized
                    , 'title', [risktype{:} ' beta: Predicted vs Realised'] ...
                    , 'drawfun', {@area @bar} ...
                    , 'style', {aLight bThin} ...
                    , 'legend', {'Predicted','Realised'} ...
                    , 'xadjust', true);
                xlim = get(gca, 'XLim');
                ylim = get(gca, 'YLim');
                text(xlim(1)+(xlim(2)-xlim(1))/2, ylim(2)-0.05*(ylim(2)-ylim(1)) ...
                    , ['\fontsize{8}\bf\color[rgb]{1 .4 0}mean(Realized): ' num2str(nanmean(realBeta(1:end-1,risktype)),'%.4f')] ...
                    , 'HorizontalAlignment','center', 'VerticalAlignment', 'top');
            end
            
            for risktype = {'Active' 'Portfolio'}
                period = mean(diff(statPeriod.return.dates));
                PeriodRet_Std = statPeriod.return_before_cost(:,risktype)./statExpRisk.expectedRisk(:,risktype)*sqrt(365/period);
                biasstat = ftsmovfun(PeriodRet_Std,12,@nanstd);
                significant = 1-sqrt(2/length(statPeriod.return.dates)) <= nanstd(PeriodRet_Std) && nanstd(PeriodRet_Std) <= 1+sqrt(2/length(statPeriod.return.dates));
                if significant
                    sigstr = '*';
                else
                    sigstr = '';
                end
                o.draw(1, biasstat(13:end) ...
                        , 'title', ['12-month Rolling Bias-Statistic: ' risktype{:}] ...
                        , 'drawfun', {@plot} ...
                        , 'hornlineposn', [0.66 1.34] ...
                        , 'style', {pThin} ...
                        , 'notes', ['Overall Bias Stat: ' num2str(nanstd(PeriodRet_Std),'%.2f') sigstr ', Min: ' num2str(nanmin(biasstat(13:end)),'%.2f') ', Max: ' num2str(nanmax(biasstat(13:end)),'%.2f')]);
            end
            
            pfalpha = o.summary(:,'expectedreturn','final');
            pfalpha(isnan(pfalpha)) = 0;
            o.draw(1, pfalpha ...
                    , 'title', 'Portfolio Expected Return' ...
                    , 'drawfun', {@plot} ...
                    , 'hornlineposn', nanmean(pfalpha) ...
                    , 'style', {pThin} ...
                    , 'notes', ['Avg Alpha: ' num2str(100*nanmean(pfalpha),'%.2f') '%, Min Alpha: ' num2str(100*nanmin(pfalpha),'%.2f') '%, Max Alpha:' num2str(100*nanmax(pfalpha),'%.2f') '%']);
            
            pickup = o.summary(:,'expectedreturn','final') - o.summary(:,'expectedreturn','initial');
            pickup(isnan(pickup)) = 0;
            o.draw(1, pickup(2:end) ...
                    , 'title', 'Alpha Pickup' ...
                    , 'drawfun', {@bar} ...
                    , 'style', {bThin} ...
                    , 'ymin', nanmin(pickup(2:end)), 'ymax', nanmax(pickup(2:end)) ...
                    , 'xadjust', true ...
                    , 'notes', ['Avg Pickup: ' num2str(100*nanmean(pickup(2:end)),'%.2f') '%, Min Pickup: ' num2str(100*nanmin(pickup(2:end)),'%.2f') '%, Max Pickup: ' num2str(100*nanmax(pickup(2:end)),'%.2f') '%']);
                
            signal = o.dataset(o.rebal.alphaId);
            signal = aligndates(signal,o.dates);
            [~,~,~,signalport] = factorPFRtn(signal,signal,signal); %this assumes signal has same coverage as benchmark
            signalto = cssum(abs(signalport-lagts(signalport,1)));
            pfto = o.summary(:,{'turnoverpct'},'final');
            w = weight(:,:,'pfweight');
            if isempty(w(w < 0))
                actness = cssum(abs(weight(:,:,'actweight')))/2;
                pfto = bsxfun(@rdivide,pfto,actness);
                legendstr = 'Adj. ';
            else
                legendstr = '';
            end
            o.draw(1, [signalto(2:end,:) pfto(2:end,:)] ...
                , 'title', [legendstr 'Turnover Comparison'] ...
                , 'drawfun', {@plot} ...
                , 'style', {pThick1, pThick4} ...
                , 'ymin', 0, 'ymax', max(fts2mat(signalto(2:end))) ...
                , 'legend', {'Signal',[legendstr 'Portfolio']});

            if ~isempty(o.rebal.volumeId)
                vol = o.dataset(o.rebal.volumeId);
                uni = o.dataset(o.rebal.benchmarkId);                
                price = leadts(aligndates(o.dataset(o.rebal.priceId), o.dataset.dates, 'calcmethod', 'exact'), 1, NaN);
                if ~isequal(vol.unit,Unit.SHARES)
                    dsprice = o.dataset(o.rebal.priceId);
                    vol = vol./dsprice;
                end
                tv = o.trd(:,:,'quantity');                
                tv = myfints(tv.dates,cell2mat(fts2mat(tv)),fieldnames(tv,1));
                vol = padfield(vol,fieldnames(tv,1),NaN,1);
                uni = padfield(uni,fieldnames(tv,1),NaN,1);
                price = padfield(price,fieldnames(tv,1),NaN,1);
                [uni, vol, price] = aligndates(uni,vol,price,tv.dates);
                tvpct = bsxfun(@rdivide,abs(tv),vol);
                tvpct = bsxfun(@times,tvpct,~isnan(uni));
                tvpct = bsxfun(@times,tvpct,~isnan(price));
                tvpct = tvpct(2:end,:);
                prc = myfints(tvpct.dates, [nanmin(fts2mat(tvpct),[],2), prctile(fts2mat(tvpct),[10 25 50 75 90],2), nanmax(fts2mat(tvpct),[],2)], {'Min' '10%' '25%' '50%' '75%' '90%' 'Max'});
                
                o.draw(1, prc*100 ...
                , 'title', 'Trade Liquidity Profile (%ADV)' ...
                , 'drawfun', {@plot} ...
                , 'ymin',  0 ...
                , 'ymax',  100*max(nanmax(fts2mat(tvpct),[],2))*1.1 ...
                , 'style', {pThick1 pThick2 pThick3 pThick4 pThick3 pThick2 pThick1} ...
                , 'legend', {'Min' '10%' '25%' '50%' '75%' '90%' 'Max'});                
            end
                
            
            flds = fieldnames(statPeriod);
            tf = ~cellfun(@isempty, regexp(flds, '^rtn_'));
            flds = flds(tf);
            num = cellfun(@(x)size(statPeriod.(x),2), flds);
            [~,idx] = sort(num);
            flds = flds(idx);
            for i = 1:length(flds)
                f = flds{i};
                fts = statPeriod.(f);
                if size(fts,2) < 2, continue; end  % no worth to draw
                
                [y_,idx] = sort(nansum(fts2mat(fts),1));
                fts = fts(:,idx);
                [T,N] = size(fts);
                if N > 60
                    o.draw(4);
                elseif N > 36
                    o.draw(3);
                elseif N > 15
                    o.draw(2);
                else
                    o.draw(1);
                end
                y = fts2mat(fts);
                y(y<0) = 0;
                barh(1:N, y', 'stacked', 'barwidth', min(0.8,N./8), 'edgecolor', 'none');
                hold on;
                y = fts2mat(fts);
                y(y>0) = 0;
                barh(1:N, y', 'stacked', 'barwidth', min(0.8,N./8), 'edgecolor', 'none');
                hold on;
                y = y_;
                y(y<0) = 0;
                barh(1:N, y', 'barwidth', min(0.2,N./(8*3)), 'edgecolor', 'none', 'facecolor', [0 1 0]);
                hold on;
                y_(y_>0) = 0;
                barh(1:N, y_', 'barwidth', min(0.2,N./(8*3)), 'edgecolor', 'none', 'facecolor', [1 0 0]);
                
                set(gca, 'FontSize', 7, 'YLim',[0.5 N+0.5], 'YTickLabel', []);
                title(['\bf\fontsize{8}Return Contribution: ' fts.desc]);
                posn = get(gca, 'position');
                
                datelabel = cellfun(@(x){datestr(x,'mmm yy')},num2cell(fts.dates));
                cb = colorbar('location', 'SouthOutside' ...);
                            , 'XLim', [1 T] ...
                            , 'XTick', [1 floor(T/2) T] ...
                            , 'XTickLabel', datelabel([1 floor(T/2) T]) ...
                            , 'FontSize', 7);
                cbPosn = get(cb, 'Position');
                cbPosn(1) = posn(1); cbPosn(3) = posn(3);      % make colorbar aligned to bar chart
                cbPosn(2) = posn(2)-cb_ygap; %cbPosn(2)-2.5*cbPosn(4);           % adjust vertical position
                cbPosn(4) = cb_h;                              % adjust height
                set(cb, 'Position', cbPosn);
                
                labels = strrep(fieldnames(fts,1),'_',' ');
                maxlen = max(cellfun(@length, labels));
                labels = cellfun(@(x){colorStr(strrep(x,'_',' '), o.figColorMap)}, labels);
%                 posn(2) = posn(2)+power(16,1/adjFactor)*0.1875*cbPosn(4); 
%                 posn(4) = posn(4)-power(16,1/adjFactor)*0.1875*cbPosn(4);
                posn(2) = posn(2)+4*cb_ygap;
                posn(4) = posn(4)-4*cb_ygap;
                xlim = get(gca, 'xlim');
                xlim(1) = xlim(1) - (xlim(2)-xlim(1))*maxlen*0.006;
                set(gca, 'Position', posn, 'xLim', xlim);
                text(ones(1,N)*xlim(1)+0.02*(xlim(2)-xlim(1)), 1:N, labels, 'HorizontalAlignment', 'left', 'FontSize', 6);
            end

            o.savefig;
            
            flds = fieldnames(statPeriod);
            tf = ~cellfun(@isempty, regexp(flds, '^comp_'));
            flds = flds(tf);
            num = cellfun(@(x)size(statPeriod.(x),2), flds);
            [~,idx] = sort(num);
            flds = flds(idx);
            for i = 1:length(flds)
                f = flds{i};
                fts = statPeriod.(f);
                if size(fts,2) < 2, continue; end  % no worth to draw
                
                [y_,idx] = sort(nanmean(fts2mat(fts),1));
                fts = fts(:,idx);
                [T,N] = size(fts);
                if N > 60
                    o.draw(4);
                elseif N > 36
                    o.draw(3);
                elseif N > 15
                    o.draw(2);
                else
                    o.draw(1);
                end
                y = fts2mat(fts./T);
                y(y<0) = 0;
                barh(1:N, y', 'stacked', 'barwidth', min(0.8,N./8), 'edgecolor', 'none');
                hold on;
                y = fts2mat(fts./T);
                y(y>0) = 0;
                barh(1:N, y', 'stacked', 'barwidth', min(0.8,N./8), 'edgecolor', 'none');
                hold on;
                y = y_;
                y(y<0) = 0;
                barh(1:N, y', 'barwidth', min(0.2,N./(8*3)), 'edgecolor', 'none', 'facecolor', [0 1 0]);
                hold on;
                y_(y_>0) = 0;
                barh(1:N, y_', 'barwidth', min(0.2,N./(8*3)), 'edgecolor', 'none', 'facecolor', [1 0 0]);
                
                set(gca, 'FontSize', 7, 'YLim',[0.5 N+0.5], 'YTickLabel', []);
                title(['\bf\fontsize{8}Weight Distribution: ' fts.desc]);
                posn = get(gca, 'position');
                
                datelabel = cellfun(@(x){datestr(x,'mmm yy')},num2cell(fts.dates));
                cb = colorbar('location', 'SouthOutside' ...);
                            , 'XLim', [1 T] ...
                            , 'XTick', [1 floor(T/2) T] ...
                            , 'XTickLabel', datelabel([1 floor(T/2) T]) ...
                            , 'FontSize', 7);
                cbPosn = get(cb, 'Position');
                cbPosn(1) = posn(1); cbPosn(3) = posn(3);      % make colorbar aligned to bar chart
                cbPosn(2) = posn(2)-cb_ygap; %cbPosn(2)-2.5*cbPosn(4);           % adjust vertical position
                cbPosn(4) = cb_h;                              % adjust height
                set(cb, 'Position', cbPosn);
                
                labels = strrep(fieldnames(fts,1),'_',' ');
                maxlen = max(cellfun(@length, labels));
                labels = cellfun(@(x){colorStr(strrep(x,'_',' '), o.figColorMap)}, labels);
%                 posn(2) = posn(2)+power(16,1/adjFactor)*0.1875*cbPosn(4); 
%                 posn(4) = posn(4)-power(16,1/adjFactor)*0.1875*cbPosn(4);
                posn(2) = posn(2)+4*cb_ygap;
                posn(4) = posn(4)-4*cb_ygap;
                xlim = get(gca, 'xlim');
                xlim(1) = xlim(1) - (xlim(2)-xlim(1))*maxlen*0.006;
                set(gca, 'Position', posn, 'xLim', xlim);
                text(ones(1,N)*xlim(1)+0.02*(xlim(2)-xlim(1)), 1:N, labels, 'HorizontalAlignment', 'left', 'FontSize', 6);
            end
            
            o.savefig;
            
            p = PDFDoc(o.repFileName);
            if ~isempty(o.strategy)
                genTabC(p,o.strategy); %Constraints Table
            end
            figfiles = cell(o.figPage,1);
            for page = 1:o.figPage
                figfiles{page} = [o.repFileName num2str(page,o.FIG_PAGE_FMT)];
            end
            p.writeln(sprintf('\\includepdf[pagecommand={\\thispagestyle{fancy}}, offset=0mm -8mm]{%s}', figfiles{:}));
            %p.figure(figfiles,'width=\textwidth');
            genTab(p, rtn, weight, alpha, 4);  % rtn is forward return
            genTabV(p, o.vios);
            p.run(2);
            rmfiles = strcat(o.repFileName, {'.tex' '.aux' '.log'});
            try
                delete(rmfiles{:}, figfiles{:});
            catch %#ok<CTCH>
            end
        end
    end
    
    methods (Static)
        function res = getViolationSummary(results)
            v = cell2mat(values(results));
            x = arrayfun(@(c) fieldnames(v(c).vios),1:length(v),'UniformOutput',false);
            dt = cell2mat(keys(results))';
            flds = unique(cat(1,x{:}));          
            soln = cell(length(dt),1);
            mat = zeros(length(dt),length(flds));
            for i=1:length(dt)
                x = v(i).vios;
                c = fieldnames(x);
                switch v(i).solts.hasSolution
                    case 1
                        soln{i} = 'Full';
                    case 2
                        soln{i} = 'Relaxed';
                    otherwise
                        soln{i} = '';
                end
                for j=1:length(c)
                    cv = x.(c{j});
                    cv = cv(:,:,'finalviolation');
                    if nansum(~isnan(cv),2) > 0
                        mat(i,strcmp(c{j},flds)) = nansum(~isnan(cv),2);
                    end
                end
            end
            idx = nansum(mat,1)~=0;
            mat = mat(:,idx);
            flds = flds(idx);
            mat = arrayfun(@(c) {num2str(c)}, mat);
            res = xts(dt,[soln, mat],[{'Solution'}, flds']);
        end
        
        function res = getConstraintSummary(str)
            assert(isa(str,'AXStrategy'),'Input must be an AXStrategy object.');
            data = cell(length(str.constraints),8);
            for i=1:length(str.constraints)
                fn = str.constraints{i}.properties;
                data(i,1) = {str.constraints{i}.id};
                data(i,2) = {str.constraints{i}.type};
                if length(str.constraints{i}.selection) > 1
                    data(i,3) = {'MULTISELECTION'};
                else
                    if isempty(str.constraints{i}.selection)
                        data(i,3) = {''};
                    else
                        data(i,3) = str.constraints{i}.selection;
                    end
                end
                if ismember({'SCOPE'},fn)
                    data(i,4) = str.constraints{i}.SCOPE;
                else
                    data(i,4) = {''};
                end
                if ismember({'UNIT'},fn)
                    data(i,5) = str.constraints{i}.UNIT;
                else
                    data(i,4) = {''};
                end
                if ismember({'MIN'},fn)
                    if length(str.constraints{i}.MIN) == 1
                        min = str.constraints{i}.MIN;
                        data(i,6) = {num2str(min{:})};
                    end
                end
                if ismember({'MAX'},fn)
                    if length(str.constraints{i}.MAX) == 1
                        max = str.constraints{i}.MAX;
                        data(i,7) = {num2str(max{:})};
                    end
                end
                
                if ismember({'MIN_VALUES_GROUP'},fn)
                    min = str.constraints{i}.MIN_VALUES_GROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        data(i,6) = {[num2str(w) '% ' min{:}]};
                    else
                        data(i,6) = min;
                    end
                end
                if ismember({'MAX_VALUES_GROUP'},fn)
                    max = str.constraints{i}.MAX_VALUES_GROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        data(i,7) = {[num2str(w) '% ' max{:}]};
                    else
                        data(i,7) = max;
                    end
                end
                
                if ismember({'MIN_VALUES_METAGROUP'},fn)
                    min = str.constraints{i}.MIN_VALUES_METAGROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        data(i,6) = {[num2str(w) '% ' min{:}]};
                    else
                        data(i,6) = min;
                    end
                end
                if ismember({'MAX_VALUES_METAGROUP'},fn)
                    max = str.constraints{i}.MAX_VALUES_METAGROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        data(i,7) = {[num2str(w) '% ' max{:}]};
                    else
                        data(i,7) = max;
                    end
                end
                
                if isempty(data{i,6})
                    data(i,6) = {''};
                end
                if isempty(data{i,7})
                    data(i,7) = {''};
                end
                
                if ismember({'BENCHMARK'},fn)
                    data(i,8) = str.constraints{i}.BENCHMARK;
                else
                    data(i,8) = {''};
                end
            end    
            
            % Pack the data into an xts
            res = xts((1:length(str.constraints))',data,{'Name','Type','Selection','Scope','Unit','Min','Max','Benchmark'});
        end
        
        function res = getStrategySummary(str)            
            assert(isa(str,'AXStrategy'),'Input must be an AXStrategy object.');
            res.objective = str.objective.id;
            for i=1:length(str.constraints)
                fn = str.constraints{i}.properties;
                res.(str.constraints{i}.id) = [];
                if all(ismember({'MIN','MAX'},fn))
                    min = str.constraints{i}.MIN;
                    max = str.constraints{i}.MAX;
                    res.(str.constraints{i}.id) = [min{:}, max{:}];
                elseif ismember({'MIN'},fn)
                    min = str.constraints{i}.MIN;
                    res.(str.constraints{i}.id) = min{:};
                elseif ismember({'MAX'},fn)
                    max = str.constraints{i}.MAX;
                    res.(str.constraints{i}.id) = max{:};
                end
                
                if all(ismember({'MIN_VALUES_GROUP','MAX_VALUES_GROUP'},fn))
                    min = str.constraints{i}.MIN_VALUES_GROUP;
                    max = str.constraints{i}.MAX_VALUES_GROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        res.(str.constraints{i}.id) = [num2str(w) '% ' min{:} ', ' num2str(w) '% ' max{:}];
                    else
                        res.(str.constraints{i}.id) = [min{:}, ', ', max{:}];
                    end
                elseif ismember({'MIN_VALUES_GROUP'},fn)
                    min = str.constraints{i}.MIN_VALUES_GROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        res.(str.constraints{i}.id) = [num2str(w) '% ' min{:}];
                    else
                        res.(str.constraints{i}.id) = min{:};
                    end
                elseif ismember({'MAX_VALUES_GROUP'},fn)
                    max = str.constraints{i}.MAX_VALUES_GROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        res.(str.constraints{i}.id) = [num2str(w) '% ' max{:}];
                    else
                        res.(str.constraints{i}.id) = max{:};
                    end
                end
                
                if all(ismember({'MIN_VALUES_METAGROUP','MAX_VALUES_METAGROUP'},fn))
                    min = str.constraints{i}.MIN_VALUES_METAGROUP;
                    max = str.constraints{i}.MAX_VALUES_METAGROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        res.(str.constraints{i}.id) = [num2str(w) '% ' min{:} ', ' num2str(w) '% ' max{:}];
                    else
                        res.(str.constraints{i}.id) = [min{:}, ', ', max{:}];
                    end
                elseif ismember({'MIN_VALUES_METAGROUP'},fn)
                    min = str.constraints{i}.MIN_VALUES_METAGROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        res.(str.constraints{i}.id) = [num2str(w) '% ' min{:}];
                    else
                        res.(str.constraints{i}.id) = min{:};
                    end
                elseif ismember({'MAX_VALUES_METAGROUP'},fn)
                    max = str.constraints{i}.MAX_VALUES_METAGROUP;
                    if ismember({'WEIGHT'},fn)
                        w = str.constraints{i}.WEIGHT;
                        w = round(100/w{:});
                        res.(str.constraints{i}.id) = [num2str(w) '% ' max{:}];
                    else
                        res.(str.constraints{i}.id) = max{:};
                    end
                end
            end
        end
        
        function res = getOptimizationSummary(results,stats)
            %% The rest of the rebalancing summary
            v = cell2mat(values(results));

            %% Initial & Final Booksize
            summ = cat(1, v.summary);
            pfval = fts2mat(summ(:,'value','final'));
            res.booksize_init = pfval(1);
            res.booksize_final = pfval(end);

            %% Average Benchmark Risk
            res.totalrisk_bm = nanmean(stats.daily.realisedRisk(:,'Benchmark'));

            %% Calculating Return
            pf_ridx = stats.daily.return(:,'Portfolio');
            act_ridx = stats.daily.return(:,'Active');
            DateSeries = genDateSeries(pf_ridx.dates(1),pf_ridx.dates(end),'A','Busdays',1,'EM',month(pf_ridx.dates(end)));
            x = {'pfret','actret','SR','IR'};
            % Preset structure names in correct order
            for j=1:4
                for i=1:5
                    res.([x{j} num2str(i) 'y']) = [];
                end
            end
            for i=1:5
                try
                    subseries = genDateSeries(datestr(DateSeries(end-i)+1,'yyyy-mm-dd'),datestr(DateSeries(end-i+1),'yyyy-mm-dd'),'d','Busdays',1);
                    [pf_subridx, act_subridx] = aligndates(pf_ridx,act_ridx,subseries);
                    res.(['pfret' num2str(i) 'y']) = nansum(pf_subridx);
                    res.(['actret' num2str(i) 'y']) = nansum(act_subridx);
                    res.(['SR' num2str(i) 'y']) = nanmean(pf_subridx)./nanstd(pf_subridx)*sqrt(252);
                    res.(['IR' num2str(i) 'y']) = nanmean(act_subridx)./nanstd(act_subridx)*sqrt(252);
                catch
                    res.(['pfret' num2str(i) 'y']) = [];
                    res.(['actret' num2str(i) 'y']) = [];
                    res.(['SR' num2str(i) 'y']) = [];
                    res.(['IR' num2str(i) 'y']) = [];
                end
            end

            %% Average Return & Risk & SR (Annual)
            res.SR = stats.daily.SR;

            %% Average Active Return & Risk & IR (Annual)
            res.IR = stats.daily.IR;

            %% Average Turnover
            res.turnover = nanmean(bsxfun(@rdivide,summ(2:end,'turnover','final'),summ(2:end,'value','final')));

            %% Average Names
            res.names = nanmean(summ(:,'count','final'));

            %% Bias Statistics
            exante = stats.exprisk.expectedRisk(:,'Portfolio');
            period = mean(diff(exante.dates));
            fwdret = stats.period.return(:,'Portfolio')*sqrt(365/period); %Annaulized Period Return
            res.biasstat_pf = nanstd(fwdret./exante);
            res.significance_pf = 1-sqrt(2/length(exante)) <= res.biasstat_pf && res.biasstat_pf <= 1+sqrt(2/length(exante));
            exante = stats.exprisk.expectedRisk(:,'Active');
            period = mean(diff(exante.dates));
            fwdret = stats.period.return(:,'Active')*sqrt(365/period); %Annaulized Period Return
            res.biasstat_act = nanstd(fwdret./exante);
            res.significance_act = 1-sqrt(2/length(exante)) <= res.biasstat_act && res.biasstat_act <= 1+sqrt(2/length(exante));
            
            %% Average TC
            res.linearTC = nanmean(summ(:,'linearTC','final'));
            res.axiomaTC = nanmean(summ(:,'axiomaTC','final'));

            %% Average Buy, Sell & #Trades
            res.buycount = nanmean(summ(:,'buycount','final'));
            res.sellcount = nanmean(summ(:,'sellcount','final'));
            res.tradecount = nanmean(summ(:,'tradecount','final'));

            %% Max Drawdown (Active & Absolute)
            pf_cumret = exp(cumsum(log(1+stats.daily.return(:,'Portfolio'))));
%             act_cumret = 1+bsxfun(@minus,exp(cumsum(log(1+stats.daily.return(:,'Portfolio')))),exp(cumsum(log(1+stats.daily.return(:,'Benchmark')))));
            act_cumret = exp(cumsum(log(1+stats.daily.return(:,'Active'))));
            res.drawdown_pf = min(fts2mat(pf_cumret./ftsmovfun(pf_cumret,Inf,@max)-1));
            res.drawdown_act = min(fts2mat(act_cumret./ftsmovfun(act_cumret,Inf,@max)-1));

            %% 2 Stdev Active & Absolute Return (+/-)
            res.ci_actret_up = nanmean(stats.period.return(:,'Active')) + 2*nanstd(stats.period.return(:,'Active'));
            res.ci_actret_down = nanmean(stats.period.return(:,'Active')) - 2*nanstd(stats.period.return(:,'Active'));
            res.ci_pfret_up = nanmean(stats.period.return(:,'Portfolio')) + 2*nanstd(stats.period.return(:,'Portfolio'));
            res.ci_pfret_down = nanmean(stats.period.return(:,'Portfolio')) - 2*nanstd(stats.period.return(:,'Portfolio'));

            %% Period Hit Ratio (Active & Absolute)
            res.up = stats.period.up;
            res.down = stats.period.down;
            res.up_abs = stats.period.up_abs;
            res.down_abs = stats.period.down_abs;               
        end
        
        function res = genSummary(str,results,stats,assetcon,attribcon)
            res.constraints = Report.getStrategySummary(str);
            if ~isempty(stats)
                res.optimization = Report.getOptimizationSummary(results,stats);
            else
                res.optimization = emptyres();
            end              
            
            % Check if optimization is successful or not
            remark = '';
            v = cell2mat(values(results));
            if v(length(v)).solts.hasSolution ~= 1
                remark = [remark 'Optimization failed at period ' num2str(length(v)) '. '];
            end
            
            % Add custom constraints to remarks
            if exist('assetcon','var')
                if ~iscell(assetcon)
                    assetcon = {assetcon};
                end
                if ~isempty(assetcon)
                    for i=1:length(assetcon)
                        if i == 1
                            remark = [remark 'Customized Holding/Trade Constraints: '];
                        end
                        remark = [remark upper(assetcon{i}.name) ', '];
                    end
                    remark = [remark(1:end-2) '. '];
                end
            end  
            
            if exist('attribcon','var')
                if ~iscell(attribcon)
                    attribcon = {attribcon};
                end
                if ~isempty(attribcon)
                    for i=1:length(attribcon)
                        if i == 1
                            remark = [remark 'Customized Attribute Constraints: '];
                        end
                        remark = [remark upper(attribcon{i}.name) ', '];
                    end
                    remark = [remark(1:end-2) '.'];
                end
            end            
            
            res.remarks.remarks = remark;
            
            function output = emptyres()
               fn = {'booksize_init';'booksize_final';'totalrisk_bm';'pfret1y';'pfret2y';'pfret3y';'pfret4y';'pfret5y';'actret1y';'actret2y';'actret3y';'actret4y';'actret5y';'SR1y';'SR2y';'SR3y';'SR4y';'SR5y';'IR1y';'IR2y';'IR3y';'IR4y';'IR5y';'SR';'IR';'turnover';'names';'biasstat_pf';'significance_pf';'biasstat_act';'significance_act';'linearTC';'axiomaTC';'buycount';'sellcount';'tradecount';'drawdown_pf';'drawdown_act';'ci_actret_up';'ci_actret_down';'ci_pfret_up';'ci_pfret_down';'up';'down';'up_abs';'down_abs';};
               for idx=1:length(fn)
                   output.(fn{idx}) = [];
               end
            end
        end
        
        function genSummaryXLS(res,filepath)
            if ~iscell(res)
                res = {res};
            end
            %% Data reformatting and treatment
            cfn = {};
            cn = cell(1,length(res));
            op = cell(1,length(res));
            rem = cell(1,length(res));
            for i=1:length(res)
                cn_i = struct2cell(convert2str(res{i}.constraints));
                cn{i} = xts(i,cn_i',fieldnames(res{i}.constraints));
                cfn = union(cfn,fieldnames(res{i}.constraints));
                op_i = struct2cell(res{i}.optimization);
                op{i} = xts(i,op_i',fieldnames(res{i}.optimization));
                rem_i = struct2cell(res{i}.remarks);
                rem{i} = xts(i,rem_i',fieldnames(res{i}.remarks));
            end                
            for i=1:length(cn)
                cn{i} = padfield(cn{i},cfn,'',1);
            end
            c = cn{1};
            o = op{1};
            r = rem{1};
            for i=2:length(cn)
                c = [c ; cn{i}];
                o = [o ; op{i}];
                r = [r ; rem{i}];
            end
            cfn = fieldnames(c,2);
            cfn = cfn(~strcmp(cfn,'objective'));
            c = c(:,[{'objective'}, cfn']);            
            %% Combine items
            cfn = fieldnames(c,2);
            ofn = fieldnames(o,2);
            fn = [{'Model'} ; cfn ; mapname(ofn)' ; {'Remarks'}];
            output_data = [num2cell(1:1:length(res))' fts2mat(c) fts2mat(o) fts2mat(r)];
            output = [fn' ; output_data];
            1;
            %% Save output to Excel
            if exist(filepath,'file') == 2
                delete(filepath)
            end
            xlswrite(filepath,output);
            %% Format
            BeginCol = ExcelCol(1);
            EndCol = ExcelCol(length(fn));
            xlsFormat(filepath,'Sensitivity Analysis',1,length(cfn)+1,BeginCol{:},EndCol{:});
            
            function xlsFormat(filename,sheetname,isdelete,hcount,begincol,endcol)
                %set the column to auto fit

                %xlsAutoFitCol(filename,sheetname,range)
                % Example:
                %xlsAutoFitCol('filename','Sheet1','A:F')

                range = [begincol ':' endcol];

                [fpath,file,ext] = fileparts(char(filename));
                if isempty(fpath)
                    fpath = pwd;
                end
                Excel = actxserver('Excel.Application');
                set(Excel,'Visible',0);
                Workbook = invoke(Excel.Workbooks, 'open', [fpath filesep file ext]);
                wks = Excel.sheets;
                wks.Item(1).Name = sheetname;
                try
                    sheet = get(Excel.Worksheets, 'Item',sheetname);
                    invoke(sheet,'Activate');

                    ExAct = Excel.Activesheet;
                   
                    Excel.Cells.Select;
                    set(Excel.Selection.Font,'Size',9);
                    
                    ExActRange = get(ExAct,'Range',range);
                    ExActRange.Select;

                    invoke(Excel.Selection.Columns,'Autofit');

                    if isdelete == 1
                        wks = Excel.sheets;
                        sidx = 1;
                        sheetidx = 1;
                        numsheet = wks.Count;
                        while sheetidx <= numsheet
                            sheetName = wks.Item(sidx).Name(1:end-1);
                            if strcmp(sheetName,'Sheet')
                                wks.Item(sidx).Delete;
                            else
                                sidx = sidx + 1; % Move to Next Sheet
                            end
                            sheetidx = sheetidx + 1; % Prevent Infinite Loop
                        end                            
                    end
                    
                    % Add Border Line
                    Range = invoke(ExAct,'Range',[begincol '1:' endcol '1']);
                    Borders = get(Range,'Borders',9);
                    set(Borders,'LineStyle',9);
                    
                    % Set Column Formats
                    ExAct.Range([cell2mat(ExcelCol(hcount+1)) ':' cell2mat(ExcelCol(hcount+2))]).Style = 'Comma';
                    ExAct.Range([cell2mat(ExcelCol(hcount+1)) ':' cell2mat(ExcelCol(hcount+2))]).NumberFormat = '0';
                    ExAct.Range([cell2mat(ExcelCol(hcount+3)) ':' cell2mat(ExcelCol(hcount+13))]).NumberFormat = '0.00%';
                    ExAct.Range([cell2mat(ExcelCol(hcount+14)) ':' cell2mat(ExcelCol(hcount+26))]).NumberFormat = '0.00';
                    ExAct.Range([cell2mat(ExcelCol(hcount+27)) ':' cell2mat(ExcelCol(hcount+27))]).NumberFormat = '0';
                    ExAct.Range([cell2mat(ExcelCol(hcount+28)) ':' cell2mat(ExcelCol(hcount+28))]).NumberFormat = '0.000';
                    ExAct.Range([cell2mat(ExcelCol(hcount+30)) ':' cell2mat(ExcelCol(hcount+30))]).NumberFormat = '0.000';
                    ExAct.Range([cell2mat(ExcelCol(hcount+32)) ':' cell2mat(ExcelCol(hcount+33))]).NumberFormat = '0.000';
                    ExAct.Range([cell2mat(ExcelCol(hcount+34)) ':' cell2mat(ExcelCol(hcount+36))]).NumberFormat = '0';
                    ExAct.Range([cell2mat(ExcelCol(hcount+37)) ':' cell2mat(ExcelCol(hcount+46))]).NumberFormat = '0.00%';
                    
                    % Conditional Formatting on SR and IR
                    Range = get(ExAct,'Range',[cell2mat(ExcelCol(hcount+14)) ':' cell2mat(ExcelCol(hcount+26))]);
                    Range.Select;
                    xlCellValue = 1;
                    Excel.Selection.FormatConditions.Delete;
                    Excel.Selection.FormatConditions.Add(xlCellValue,6,'0');
                    Excel.Selection.FormatConditions.Item(1).Font.Color = -16383844;
                    Excel.Selection.FormatConditions.Item(1).Interior.Color = 13551615;
                    
                    % Save workbook
                    invoke(Workbook, 'Save');
                    invoke(Excel, 'Quit');
                catch e
                    invoke(Excel, 'Quit');
                    rethrow(e);
                end
                delete(Excel);
            end
            
            function Out=ExcelCol(In)
            %EXCELCOL  Converts between column name and number for Excel representation
            %   Out=ExcelCol(In) takes the input In, which may be a number, vector,
            %   char, or cell and converts it to the other representation
            %
            %   If IN is numeric, output will be a column cell of the column name
            %   If IN is char or cell, output will be a number or column vector, 
            %      ignoring any numberic part which may be included in input
            %
            %   EXAMPLES:
            %   ExcelCol(100)                        %Number to column name
            %   ExcelCol('CV')                       %Column name to number
            %   ExcelCol([1 10 100 1000 16383])      %Multiple conversions
            %   ExcelCol({'A' 'J' 'CV' 'ALL' 'XFC'}) %Multiple conversions
            %
            % $ Author: Mike Sheppard
            % $ Original Date: 4/7/2010
            % $ Version: 1.0
            
                %Optional to change representation and base
                ABC='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                base=26; 

                if isnumeric(In)
                %Converts from column number to alpha
                %1=A, 2=B,... 26=Z, 27=AA, ... 16383=XFC
                In=In(:);
                if ~all(In>0)
                error('MATLAB:ExcelCol:NegativeColumnNumber', 'Column numbers must be positive');    
                end
                  for row=1:size(In,1)
                   diff=1;
                   i=0;
                   n=In(row,:);
                   while diff<=n
                       letter_ind=1+mod(floor((n-diff)/base^i),base);
                       i=i+1;
                       temp(i)=ABC(letter_ind);
                       diff=diff+base^i;
                   end
                   Out{row}=fliplr(temp);
                   clear temp
                  end  
                  Out=Out(:);
                else
                %Converts from alpha to column number
                %A=1, B=2, ..., Z=26, AA=27, ... XFC=16383   
                   In=cellstr(upper(In));
                   In=In(:);
                   for row=1:size(In,1)
                       alpha=char(In(row,:));
                       %Delete any numbers which may appear
                       alpha=(char(regexp(alpha,'\D','match')))';
                       lng=length(alpha);
                       temp=((base^(lng) - 1) / (base-1));
                       for i=1:lng
                           ind=strfind(ABC, alpha(i));
                           if isempty(ind)  %ERROR
                                 error('MATLAB:ExcelCol:Mixofcharacters', 'Must be only alpha-numeric values {A-Z}, {a-z}, {0-9}');
                           end
                           temp=temp+(ind-1)*(base^(lng-i));
                       end
                       Out(row)=temp;
                   end
                   Out=Out(:);
                end
            end
            
            function res = convert2str(res)
                fn_res = fieldnames(res);
                for r=1:length(fn_res)
                    if ~ischar(res.(fn_res{r}))
                        if length(res.(fn_res{r})) == 1
                            res.(fn_res{r}) = num2str(res.(fn_res{r}));
                        else
                            arr = res.(fn_res{r});
                            str = '';
                            for j=1:length(arr)
                                if j == length(arr)
                                    str = [str num2str(arr(j))];
                                else
                                    str = [str num2str(arr(j)) ','];
                                end
                            end
                            res.(fn_res{r}) = str;
                        end
                    end
                end
            end 
            
            function res = mapname(res)
                init =  {'booksize_init','booksize_final','totalrisk_bm','pfret1y','pfret2y','pfret3y','pfret4y','pfret5y' ... 
                        ,'actret1y','actret2y','actret3y','actret4y','actret5y','SR1y','SR2y','SR3y','SR4y','SR5y' ...
                        ,'IR1y','IR2y','IR3y','IR4y','IR5y','SR','IR','turnover','names','biasstat_pf','significance_pf','biasstat_act','significance_act','linearTC' ...
                        ,'axiomaTC','buycount','sellcount','tradecount','drawdown_pf','drawdown_act','ci_actret_up' ...
                        ,'ci_actret_down','ci_pfret_up','ci_pfret_down','up','down','up_abs','down_abs'};
                final = {'Initial Book Size','Final Book Size','Benchmark Risk','PFRet1Y','PFRet2Y','PFRet3Y','PFRet4Y','PFRet5Y' ... 
                        ,'ActRet1Y','ActRet2Y','ActRet3Y','ActRet4Y','ActRet5Y','SR1Y','SR2Y','SR3Y','SR4Y','SR5Y' ...
                        ,'IR1Y','IR2Y','IR3Y','IR4Y','IR5Y','SR','IR','Turnover','Names','Bias Statistic (PF)','Significance (PF)','Bias Statistic (Act)','Significance (Act)','Linear TC' ...                       
                        ,'Axioma TC','Buy Count','Sell Count','Trade Count','PF Drawdown','Active Drawdown','ActRet CI (+)' ...
                        ,'ActRet CI (-)','PFRet CI (+)','PFRet CI (-)','Up Market (Act)','Down Market (Act)','Up Market (PF)','Down Market (PF)'};
                [~, loc] = ismember(res,init);
                res = final(loc);
            end
        end
        
        function res = getResults(results,name,field)
            % Loads in the results Container.Map and output final portfolio
            % as myfints based on the fieldname
            assert(isa(results,'containers.Map'),'Invalid parameter type for input results.');
            assert(ismember(name,{'pfinit','pffinal','trd'}),'Invalid name.');
            v = cell2mat(values(results));
            data = {v.(lower(name))};
            [data{:}] = alignfields(data{:}, 'union', 1);
            data = cat(1, data{:});
            assert(ismember(field,fieldnames(data,1,2)),'Invalid field.');
            res = data(:,:,field);
        end
                
        function res = getFactorExp(results,factorid)
            v = cell2mat(values(results));
            data = {v.pffinal};
            [data{:}] = alignfields(data{:}, 'union', 1);
            data = cat(1, data{:});
            pf = data(:,:,{'bmweight','pfweight','actweight'});
            facts = LoadFactorTS(fieldnames(pf,1,1),factorid,datestr(min(pf.dates)-31,'yyyy-mm-dd'),datestr(max(pf.dates),'yyyy-mm-dd'),0);
            [pf facts] = aligndates(pf,facts);
            [pf facts] = alignfields(pf,facts,1);
            res = squeeze(uniftsfun(bsxfun(@times,pf,facts), ...
                @(x)nansum(x,2), {'facexp',{'Benchmark' 'Portfolio' 'Active'}}));
            res.desc = 'facexp';
        end
        
        function gencsv(name,stats,mode)
            if ~exist('mode','var')
                mode = 'daily';
            end
            
            switch lower(mode)
                case {'daily'}
                    ret_pf = stats.daily.return(:,'Portfolio');
                    ret_bm = stats.daily.return_before_cost(:,'Benchmark');
                case {'period'}
                    ret_pf = stats.period.return(:,'Portfolio');
                    ret_bm = stats.period.return_before_cost(:,'Benchmark');
            end
            
            date_pf = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},ret_pf.dates);
            ret_pf = fts2mat(ret_pf);
            date_bm = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},ret_bm.dates);
            ret_bm = fts2mat(ret_bm);
            
            fid = fopen([name '_PF.csv'],'wt');
            for i=1:numel(date_pf)
                fprintf(fid,'PF,%s,%16.16f\n',date_pf{i},ret_pf(i));
            end
            fclose(fid);
            
            fid = fopen([name '_BM.csv'],'wt');
            for i=1:numel(date_bm)
                fprintf(fid,'BM,%s,%16.16f\n',date_bm{i},ret_bm(i));
            end
            fclose(fid);
        end
    end
        
    methods (Access = private)       
        function rho = alphaAutoCorr(o, nBackPeriods)
        % period
            alpha = aligndates(o.dataset(o.rebal.alphaId), o.dates);
            rho = cell(nBackPeriods,1);
            for t = 1:nBackPeriods
                rho{t} = csrankcorr(alpha, lagts(alpha,t,NaN));
            end
            rho = [rho{:}];
        end
        
        function stat = onDailyReturn(o)
        % daily return
%             rtn = o.totalPrice ./ lagts(o.totalPrice,1,NaN) - 1;   
            rtn = leadts(o.totalPrice,1,NaN) ./ o.totalPrice - 1;
            rtn = rtn(rtn.dates >= o.dates(1) & rtn.dates <= o.dates(end), :);
           
            price = padfield(o.dataset(o.rebal.priceId), fieldnames(o.pffinal,1,1), NaN); % daily close price
            [price, pfshare] = aligndates(price, o.pffinal(:,:,'share'), rtn.dates);
            pfshare = fill(pfshare, inf, 'row');
            pfweight = pfshare .* price;
            pfweight = bsxfun(@rdivide, pfweight, cssum(abs(pfweight)));

            bmshare = o.pffinal(:,:,'bmweight') ./ o.pffinal(:,:,'price'); % use period price
            bmshare = aligndates(bmshare, rtn.dates);
            bmshare = fill(bmshare, inf, 'row');
            bmweight = bmshare .* price;
            bmweight = bsxfun(@rdivide, bmweight, cssum(abs(bmweight)));
            
            actweight = pfweight - bmweight;
            
            weight = cat(3, actweight, pfweight, bmweight);
            
            % daily active return and cumulative return
            stat.return_before_cost = squeeze(uniftsfun(bsxfun(@times,weight,rtn), ...
                @(x)nansum(x,2), {'return',{'Active' 'Portfolio' 'Benchmark'}}));
            stat.return_before_cost = lagts(stat.return_before_cost,1);
            stat.return = stat.return_before_cost;
            cost = bsxfun(@rdivide, o.summary(:,'tcost','final'), o.summary(:,'value','final'));
            borrowcost = bsxfun(@rdivide, o.summary(:,'borrowcost_ann','final'), o.summary(:,'value','final')).*(mean(diff(o.dates))/252);
            cost = bsxfun(@plus,cost,borrowcost);
            cost = aligndates(cost, stat.return.dates);
            cost(isnan(cost)) = 0;
            stat.return(:,{'Active','Portfolio'}) = bsxfun(@minus, stat.return_before_cost(:,{'Active','Portfolio'}), cost);

            annualizedFactor = sqrt(252);
            if size(stat.return(:,'Active'),1) <= 500 && size(stat.return(:,'Active'),1) >= 30
                stat.estfreq = 90;
            elseif size(stat.return(:,'Active'),1) > 500
                stat.estfreq = 252;
            else
                stat.estfreq = 5;
            end
                
            stat.IR = nanmean(stat.return(:,'Active')) ./ nanstd(stat.return(:,'Active')) .* annualizedFactor;
            stat.SR = nanmean(stat.return(:,'Portfolio')) ./ nanstd(stat.return(:,'Portfolio')) .* annualizedFactor;
            stat.annualIR = ftsmovfun(stat.return(:,'Active'), stat.estfreq, @(x)nanmean(x)./nanstd(x)) .* annualizedFactor;
            stat.annualSR = ftsmovfun(stat.return(:,'Portfolio'), stat.estfreq, @(x)nanmean(x)./nanstd(x)) .* annualizedFactor;
            cutoff = 1:min(stat.estfreq, size(stat.annualIR,1));
            stat.annualIR(cutoff,:) = [];
            stat.annualSR(cutoff,:) = [];
            
            w = weight(:,:,2);
            stret = stat.return_before_cost;
            if ~isempty(w(w < 0))
                mkt = o.dataset(['X' upper(strrep(o.dataset.aggid{1},' ','_'))])/100.0;
                mkt = padfield(mkt,fieldnames(o.pffinal(:,:,'price'),1), NaN, 1);
                dsprice = aligndates(o.pffinal(:,:,'price'),mkt.dates);
                mshare = mkt ./ dsprice;
                mshare = aligndates(mshare, rtn.dates);
                mshare = fill(mshare, inf, 'row');
                mweight = mshare .* price;
                weight(:,:,3) = bsxfun(@rdivide, mweight, cssum(abs(mweight)));
                
                mktret = squeeze(uniftsfun(bsxfun(@times,weight,rtn), ...
                @(x)nansum(x,2), {'return',{'Active' 'Portfolio' 'Benchmark'}}));
                stret(:,'Benchmark') = mktret(:,'Benchmark');
            end            
            
            stat.realisedRisk = ftsmovfun(stret, o.ROLLING_WINDOW, @nanstd)*sqrt(252);
            stat.realisedBeta = [ftsmovfun(stret(:,[1 3]), o.ROLLING_WINDOW, @betafun, 'Active') ...;
                                 ftsmovfun(stret(:,[2 3]), o.ROLLING_WINDOW, @betafun, 'Portfolio')];

            function x = betafun(x)
                if size(x,1) < 2
                    x = NaN;
                else
                    x = nancov(x);
                    x = x(1,2) ./ x(2,2);
                end
            end
        end
        
        function stat = expectedRisk(o)
            % period
            rm = o.dataset(o.rebal.riskmodelId);
            rsk = nan(length(o.dates),3);
            beta = nan(length(o.dates),3);
            weight = o.pffinal(:,:,{'actweight' 'pfweight' 'bmweight'});
            weight = padfield(weight, fieldnames(rm.specrisk,1,1), NaN, 1);
            w = weight(:,:,'pfweight');
            if ~isempty(w(w < 0)) % Long/Short scenario
                bm = o.dataset(['X' upper(strrep(o.dataset.aggid{1},' ','_'))])/100.0;
                bm = padfield(bm,fieldnames(weight,1), NaN, 1);
                weight(:,:,'bmweight') = aligndates(bm,weight.dates);
            end
            for i=1:3
                rsk(:,i) = rm.calcrisk(weight(:,:,i));
                beta(:,i) = rm.calcbeta(weight(:,:,i));
            end      
            stat.expectedRisk = myfints(o.dates, rsk, {'Active' 'Portfolio' 'Benchmark'});
            stat.expectedBeta = myfints(o.dates, beta(:,[1 2]), {'Active' 'Portfolio'});
        end
        
        function [stat, rtn, weight, alpha] = onPeriodReturns(o)
        % period
        % stat contains some statistics on portfolio level
        % rtn and weight are xts contain returns and weights of individual stocks
            period = mean(diff(o.dates));
            periodDates = [o.dates(1)-period; o.dates; o.dates(end)+period];
            rtn = aligndates(o.totalPrice, periodDates);
            rtn = leadts(rtn,1,NaN) ./ rtn - 1;  % forward return
            rtn([1 end],:) = [];  %
            
            weight = o.pffinal(:,:,{'actweight' 'pfweight' 'bmweight'});
            cost = bsxfun(@rdivide, o.summary(:,'tcost','final'), o.summary(:,'value','final'));
            borrowcost = bsxfun(@rdivide, o.summary(:,'borrowcost_ann','final'), o.summary(:,'value','final')).*(period/252);
            cost = bsxfun(@plus,cost,borrowcost);
            alpha = o.dataset(o.rebal.alphaId);
 
            % Extra Analytics - Alpha Quintile Breakdown, Liquidity Bucket, Specific Risk Bucket
            quintile = normalize(alpha,'method','rankbucket5','mode','descend');
            o.dataset.add('ALPHAQUINTILE',quintile,'METAGROUP');
            
            if ~isempty(o.rebal.volumeId)
                vol = o.dataset(o.rebal.volumeId);
                dsprice = o.dataset(o.rebal.priceId);
                [dsprice, vol] = aligndates(dsprice,vol);
                if isequal(vol.unit,Unit.SHARES)
                    vol = vol.*dsprice;
                end
                lqtile = normalize(vol,'method','rankbucket5','mode','descend');
                o.dataset.add('LIQUIDITY',lqtile,'METAGROUP');
            end                
            
            rm = o.dataset(o.rebal.riskmodelId);
            srtile = normalize(rm.specrisk,'method','rankbucket5','mode','descend');
            o.dataset.add('SPECRISK',srtile,'METAGROUP');
            
            % Retrieve metagroup
            vals = values(o.dataset, 'METAGROUP');
            [rtn, weight, alpha, cost, vals{:}] = aligndates (rtn, weight, alpha, cost, vals{:}, o.dates);
            [rtn, weight, alpha, vals{:}] = alignfields(rtn, weight, alpha, vals{:}, 1);

            stat.return_before_cost = squeeze(uniftsfun(bsxfun(@times,weight,rtn), ...
                @(x)nansum(x,2), {'return',{'Active' 'Portfolio' 'Benchmark'}}));
            stat.return = bsxfun(@minus, stat.return_before_cost(:,{'Active' 'Portfolio'}), cost);
            stat.return = [stat.return stat.return_before_cost(:,'Benchmark')];
            rtn_excess = bsxfun(@minus, rtn, stat.return_before_cost(:,'Benchmark'));            
            
            [~, ~, ~, ~, alpha_lw, alpha_sw] = factorPFRtn(alpha, rtn, weight(:,:,'bmweight'));
            alpha_lw = alpha_lw + weight(:,:,'bmweight'); %reversing the calculation in factorPFRtn
            alpha_sw = alpha_sw - weight(:,:,'bmweight'); %reversing the calculation in factorPFRtn
            alpha_plw = alpha_lw;
            alpha_psw = alpha_sw;
            lw = weight(:,:,'actweight');
            sw = lw;
            lw(lw < 0) = 0;
            sw(sw > 0) = 0;
            alpha_lw = bsxfun(@times, alpha_lw, abs(cssum(lw)));
            alpha_sw = bsxfun(@times, alpha_sw, abs(cssum(sw)));
            plw = weight(:,:,'pfweight');
            psw = plw;
            plw(plw < 0) = 0;
            psw(psw > 0) = 0;
            alpha_plw = bsxfun(@times, alpha_plw, abs(cssum(plw)));
            alpha_psw = bsxfun(@times, alpha_psw, abs(cssum(psw)));
%             w = cat(3, lw, sw, alpha_lw, alpha_sw, plw, psw, alpha_plw, alpha_psw);
%             stat.return_attribution = squeeze(uniftsfun(bsxfun(@times, w, rtn_excess), ...
%                 @(x)nansum(x,2), {'return',{'Long' 'Short' 'Alpha Long' 'Alpha Short' 'PF Long' 'PF Short', 'Alpha PF Long', 'Alpha PF Short'}}));
            w1 = cat(3, lw, sw, alpha_lw, alpha_sw);
            w2 = cat(3, plw, psw, alpha_plw, alpha_psw);
            act_attrib = uniftsfun(bsxfun(@times, w1, rtn_excess), ...
                @(x)nansum(x,2), {'return',{'Long' 'Short' 'Alpha Long' 'Alpha Short'}});
            abs_attrib = uniftsfun(bsxfun(@times, w2, rtn), ...
                @(x)nansum(x,2), {'return',{'PF Long' 'PF Short', 'Alpha PF Long', 'Alpha PF Short'}});
            stat.return_attribution = squeeze(cat(3,act_attrib,abs_attrib));
            
            actRtn = bsxfun(@minus, rtn, stat.return_before_cost(:,'Benchmark'));  % now active return
            w = weight(:,:,'pfweight');
            rdummy = xts(rtn.dates,ones(size(rtn)),fieldnames(rtn,1));
            for v = vals(:)'                
                if ~isempty(w(w < 0)) %If shorting exists, plot in absolute return space
                    stat.(['rtn_' v{:}.id]) = aggregate(rtn, v{:}, weight(:,:,'pfweight'));
                    stat.(['comp_' v{:}.id]) = aggregate(rdummy, v{:}, weight(:,:,'pfweight'));
                else
                    stat.(['rtn_' v{:}.id]) = aggregate(actRtn, v{:}, weight(:,:,'actweight'));
                    stat.(['comp_' v{:}.id]) = aggregate(rdummy, v{:}, weight(:,:,'actweight'));
                end
                stat.(['rtn_' v{:}.id]).desc = v{:}.id;
                stat.(['comp_' v{:}.id]).desc = v{:}.id;
            end
            
            if ~isempty(w(w < 0))
                stat.rtn_w = aggregate(rtn, weight(:,:,'pfweight')>=0, weight(:,:,'pfweight'));
                stat.rtn_w = chfield(stat.rtn_w, fieldnames(stat.rtn_w,1), {'Short' 'Long'});
                stat.rtn_w.desc = 'Weights';
                stat.ic = csrankcorr(alpha, rtn);
                stat.impic = csrankcorr(weight(:,:,'pfweight'), rtn);
            else
                stat.rtn_w = aggregate(actRtn, weight(:,:,'actweight')>=0, weight(:,:,'actweight'));
                stat.rtn_w = chfield(stat.rtn_w, fieldnames(stat.rtn_w,1), {'Under Weight' 'Over Weright'});
                stat.rtn_w.desc = 'Weights';
                stat.ic = csrankcorr(alpha, actRtn);
                stat.impic = csrankcorr(weight(:,:,'actweight'), actRtn);
            end

            idx = stat.return_before_cost(:,'Benchmark') >= 0;
            stat.up = nansum(fts2mat(stat.return(:,'Active') >= 0) & fts2mat(idx)) ./ nansum(fts2mat(idx));
            stat.up_abs = nansum(fts2mat(stat.return(:,'Portfolio') >= 0) & fts2mat(idx)) ./ nansum(fts2mat(idx));
            idx = stat.return(:,'Benchmark') < 0;
            stat.down = nansum(fts2mat(stat.return(:,'Active') >= 0) & fts2mat(idx)) ./ nansum(fts2mat(idx));
            stat.down_abs = nansum(fts2mat(stat.return(:,'Portfolio') >= 0) & fts2mat(idx)) ./ nansum(fts2mat(idx));                       
            
            rmax = nanmax(stat.return(:,'Active'));
            r = (0:rmax/12:rmax)';
            if ~isempty(w(w < 0))
                stat.omega = [r omegaRatio(stat.return(:,'Portfolio'), r)];
            else
                stat.omega = [r omegaRatio(stat.return(:,'Active'), r)];
            end
        end
        
        function savefig(o)
            o.figPage = o.figPage + 1;
            fname = [o.repFileName num2str(o.figPage, o.FIG_PAGE_FMT)];
            %saveas(gcf, fname, 'psc2');
            saveas(gcf, fname);
            close
            o.figLayout(:) = false;
        end

        function drawCore(o, range, varargin)
            [nCol, nRow] = size(o.figLayout); % Note the switch row and col
            o.figLayout(range) = true;
            
            if ~isempty(varargin)
                if isa(varargin{1}, 'myfints')
                    legendidx = 2*find(ismember(varargin(2:2:end), 'legend'))+1;
                else
                    legendidx = 2*find(ismember(varargin(3:2:end), 'legend'))+2;
                end
                if ~isempty(legendidx) % modify legend option
                    %varargin{legendidx} = [varargin(legendidx),'Orientation','vertical','location','NorthWest','fontsize',6];
                    legendstr = varargin{legendidx};
                    varargin([legendidx-1 legendidx]) = [];
                end
                
                varargin = [varargin, 'layout', [nRow nCol], 'range', {{range}}];
                if all(range > 1) % there exists a figure
                    varargin = [varargin 'figure' gcf];
                end
                tsplot(varargin{:});
                
                if ~isempty(legendidx)
                    simpleLegend(legendstr, o.figColorMap);
                end
            else
                if any(range == 1) % new page, new figure
                    figure;
                    paperPos = [0, (29.7-min(8*nRow,29.7))/2, 21, min(8*nRow, 29.7)];
                    set(gcf, 'PaperUnits', 'centimeters', ...
                        'PaperType', 'A4', ...
                        'PaperPosition', paperPos, ...
                        'Units', 'centimeters');
                end
                subplot(nRow, nCol, range);
            end
            
            if any(range == 1) % just created a new figure
                colormap(o.figColorMap);
            end

            o.figCounter = o.figCounter + 1;
        end
        
        function draw(o, nAreas, varargin)
            if nargin < 2, nAreas = 1; end
            range = findRange(o.figLayout, nAreas);
            if isempty(range)
                o.savefig;
                range = findRange(o.figLayout, nAreas);
            end
            o.drawCore(range, varargin{:});
        end
    end
end

function a = findRange(layout, nAreas)
    if nAreas == 1
        a = find(~layout(:), 1, 'first');
    else
        str = num2str(layout,'%1d');
        pattern = repmat('0', 1, nAreas);
        for i = 1:size(str,1)
            k = strfind(str(i,:), pattern);
            if ~isempty(k)
                str(i,k:k+nAreas-1) = 'A';
                a = find(str(:)=='A');
                return;
            end
        end
        a = [];
    end
end

function fts = aggregate(fts, grpMap, weight)
    % Examples of use of aggregate:
    %    %% Calculate sector/country level analytics (active level) and store in structure
    %    sectorfts  = padfield(getExport(o.dataset('SECTOR')), fieldnames(bmweight,1));
    %    countryfts = padfield(getExport(o.dataset('COUNTRY')), fieldnames(bmweight,1));
    %    sector.bmweight = aggregate(bmweight, sectorfts);
    %    sector.actweight = aggregate(pfactwgt, sectorfts);
    %    country.bmweight = aggregate(bmweight, countryfts);
    %    country.actweight = aggregate(actweight, countryfts);
    if nargin < 3, weight = ones(size(fts)); end
    FTSASSERT(isaligneddata(fts, grpMap));
    grpMap = fts2mat(grpMap);
    if iscell(grpMap)
        idx = cellfun(@(c) any(isnan(c)),grpMap);
        if nansum(nansum(idx,2)) > 0
            grpMap(idx) = repmat({'UNIDENTIFIED'},size(grpMap(idx)));
        end
    end
    grpNames = unique(grpMap);
    if isnumeric(grpNames)
        grpNames(isnan(grpNames)) = [];
    end
    [~,numGrpMap] = ismember(grpMap, grpNames);
    if ~iscell(grpNames)
        grpNames = mat2cell(num2str(grpNames(:)),ones(size(grpNames)));
    end
    fts = biftsfun(fts, weight, @aggfun, grpNames);

    function res = aggfun(x, w)
        [T,N] = size(x);
        % w(isnan(x)) = NaN;  %%% This excludes those NaNs in x. if no normalize, no use
        nGrp = length(grpNames);
        res = NaN(T, nGrp);
        for i = 1:nGrp
            idx = numGrpMap == i;
            x_ = NaN(T,N);
            w_ = NaN(T,N);
            x_(idx) = x(idx);
            w_(idx) = w(idx);
            res(:,i) = nansum(x_.*w_,2);
        end
    end
end
        
function omr = omegaRatio(rtn, r)
% \Omega(r) = \frac{\int_r^\infty (1-F(x))dx}{\int_{-\infty}^r F(x)dx}
    rtn = sort(fts2mat(rtn));
    prob = ((1:length(rtn))-0.5)' ./ length(rtn);
    r = sort(r);
    omr = nan(size(r));
    for i = 1:length(r)
        idx = rtn <= r(i);
        omr(i) = integral(rtn(~idx),1-prob(~idx)) ./ integral(rtn(idx),prob(idx));
    end
    
    omr(isinf(omr)) = NaN;
    
    function v = integral(x,p)
        if numel(x) < 2
            v = 0;
        else
            v = (p(1:end-1)+p(2:end))' * diff(x) ./ 2;
        end
    end
end

function plot3D(fts) %#ok<DEFNU>
% begin plotting
    x = fts.dates;
    xlabels = datestr(x, 'mmm yy');
    x = x - x(1);
    y = 1:size(fts,2);
    surf(x, y, fts2mat(fts)');
    set(gca, 'FontSize', 8);

    % set y axis
    set(gca, 'YLim', y([1 end]));
    %set(gca, 'YTick', y(1:6:end));
    set(gca, 'YTickLabel', y);
    h = ylabel('lags', 'Rotation', -25, 'FontSize', 8);
    pos = get(h, 'Position');
    set(h, 'Position', [pos(1) pos(2) pos(3)]);

    % set x axis
    m = length(x);
    labelStep = round(m/10);
    labeledIdxs = 1:labelStep:m;
    if labeledIdxs(end) ~= m
        if m - labeledIdxs(end) < labelStep/2  % two x-lables too close, remove one
            labeledIdxs(end) = [];
        end
        labeledIdxs(end + 1) = m;
    end
    xlabels = xlabels(labeledIdxs,:);
    xticks  = x(labeledIdxs);
    set(gca, 'XLim', x([1 end]));
    set(gca, 'XTick', xticks);
    set(gca, 'XTickLabel', xlabels);
    h = xlabel('time', 'Rotation', 15, 'FontSize', 8);
    pos = get(h, 'Position');
    set(h, 'Position', [pos(1) pos(2) pos(3)])

    % then z axis
    zlabel('autocorrelation', 'FontSize', 8);
    shading interp;
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

function simpleLegend(legendstr, cmap)
    children = graph2dhelper('get_legendable_children', gca);
    str1 = '\bf';
    str2 = '\bf';
    n = min(length(children),length(legendstr))-1;
    cidx = round(1:size(cmap,1)/n-1:size(cmap,1));
    for i = 1:min(length(children),length(legendstr))
        if strcmpi(get(children(i), 'Type'), 'line')
            color = get(children(i), 'color');
        else
            color = get(children(i), 'facecolor');
        end
        if ischar(color) && strcmpi(color, 'flat')
            color = cmap(cidx(i),:);
        end
        str1 = [str1 '\color[rgb]{' num2str(color,'%.5f ') '}{\fontsize{11}\bullet} \color[rgb]{0 0 0}' legendstr{i} '  ']; %#ok<AGROW>
        str2 = [str2 '\color[rgb]{0.3 0.3 0.3}{\fontsize{11}\bullet} \color[rgb]{1 1 1}' legendstr{i} '  ']; %#ok<AGROW>
    end

    cb_ygap = 0.0045;
    posn = get(gca, 'position');
    posn(2) = posn(2)+2.5*cb_ygap;             
    posn(4) = posn(4)-2.5*cb_ygap;
    set(gca, 'Position', posn);
    yLim = get(gca, 'YLim');
    xLim = get(gca, 'XLim');
    x1 = xLim(1) + (xLim(2)-xLim(1))/2;
    y1 = yLim(1) - (yLim(2)-yLim(1))/5;
    x2 = x1 + (xLim(2)-xLim(1))*0.003;
    y2 = y1 - (yLim(2)-yLim(1))*0.005;
    text(x2, y2, str2, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 7);
    text(x1, y1, str1, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 7);
end

function str = colorStr(str, cmap)
    n = numel(str);
    T = size(cmap,1);
    idx = floor(1:T/n:T);
    idx(end:n) = idx(end);
    str = strcat('\bf\color[rgb]{', num2str(cmap(idx,:),'%.5f '), '}', str(:));
    str = str';
    str = str(:)';
end

function genTabC(p,str)
    table = Report.getConstraintSummary(str); %Load Table as xts
    body = fts2mat(table);
    for i=1:size(body,1)
        if mod(i,2)
            body{i,1} = strcat('\rowcolor{cone}',body{i,1});
        else
            body{i,1} = strcat('\rowcolor{ctwo}',body{i,1});
        end
    end
    title = fieldnames(table,1)';
    title = strcat('\multicolumn{1}{c}{', title, '}');
    p.writeln('\setlength{\tabcolsep}{5pt}');
    body = regexprep(body,'_','\\$0');
    body = regexprep(body,'%','\\$0');
    p.writeln('\footnotesize');
    p.table('Constraints Summary', title, body, 'l l l l l l l l', 'landscape');
    p.writeln('\normal');
end

function genTabV(p,table)
    body = fts2mat(table);
    tstr = arrayfun(@(c) {datestr(c,'yyyy-mm-dd')},table.dates);
    body = [tstr body];
    for i=1:size(body,1)
        if mod(i,2)
            body{i,1} = strcat('\rowcolor{cone}',body{i,1});
        else
            body{i,1} = strcat('\rowcolor{ctwo}',body{i,1});
        end
    end
    title = [{'Date'}, fieldnames(table,1)'];
    title = strcat('\multicolumn{1}{c}{', title, '}');
    p.writeln('\setlength{\tabcolsep}{5pt}');
    body = regexprep(body,'_','\\$0');
    body = regexprep(body,'%','\\$0');
    p.writeln('\newpage\footnotesize');
    lcr = repmat('l ',size(body,2) + 1, 1);
    p.table('Violations Summary', title, body, lcr(1:end-1), 'landscape');
    p.writeln('\normal');
end

function genTab(p, rtn, weight, alpha, nPickup)
% rtn is forward return
% rtn, weight, alpha required to be aligned 
    T = size(rtn, 1);
    
    %mrfmt = ['\multirow{' num2str(nPickup,'%d') '}{c}{%s}'];
    mrfmt = '%s';
    body = cell(T*nPickup, 10);
    body(:) = {''};
    body(1+((1:T)-1)*nPickup, 1) = ...   % first column: dates
        PDFDoc.format(mat2cell(datestr(rtn.dates,'yyyy-mm-dd'), ones(T,1)), true(T,1), mrfmt);

    rank = fts2mat(normalize(rtn, 'mode', 'descend', 'method', 'rank', 'weight', weight(:,:,'bmweight')));
    secids = fieldnames(rtn, 1);
    rtn   = fts2mat(rtn);
    alpha = fts2mat(alpha);  % assume alpha already aligned to other stuff
    for t = 1:T
        tidx = 1+(t-1)*nPickup : t*nPickup;
        sidx = rank(t,:) <= nPickup/2 | rank(t,:) > nanmax(rank(t,:))-nPickup/2;
        sloc = find(sidx);
        [~, ix] = sort(rank(t,sloc));
        sloc = sloc(ix);
        body(tidx, 4) = secids(sloc);
        body(tidx, 5) = cellfun(@(x){num2str(x,'%.3f')}, num2cell(alpha(t,sloc)));
        w = squeeze(weight(t, sloc, {'pfweight' 'actweight'}));  %% 'bmweight'
        r = rtn(t,sloc)';
        r_w = bsxfun(@times, w, r);
        body(tidx, 6:10) = cellfun(@(x){num2str(x,'%.3f')}, num2cell([r w r_w]*100));
        
        w = squeeze(weight(t, :, {'pfweight' 'actweight'}));  %% 'bmweight'
        r = rtn(t,:)';
        r_w = bsxfun(@times, w, r);
        pfr = nansum(r_w, 1)*100;
        body(1+(t-1)*nPickup,2) = {strrep(mrfmt, '%s', num2str(pfr(1),'%.3f'))};
        body(1+(t-1)*nPickup,3) = {strrep(mrfmt, '%s', num2str(pfr(2),'%.3f'))};
        if mod(t,2)
            body(tidx,1) = strcat('\rowcolor{cone}',body(tidx,1));
        else
            body(tidx,1) = strcat('\rowcolor{ctwo}',body(tidx,1));
        end
    end
    
    body(1:end-nPickup,1) = body(nPickup+1:end,1);
    body(end-nPickup+1:end,:) = [];
    T = T - 1;
    nRowsPerPage = floor(38/nPickup) * nPickup;
    pageBreakIdx = nRowsPerPage+1 : nRowsPerPage : T*nPickup;
    body(pageBreakIdx,1) = strcat('\pagebreak', body(pageBreakIdx,1));
    rowRuleIdx = setdiff(nPickup+1:nPickup:T*nPickup, pageBreakIdx);
    body(rowRuleIdx,1) = strcat('\midrule', body(rowRuleIdx,1));
    
    title = {'Date' 'R_{PF}' 'R_{Act}' 'Id' 'Signal' 'R' 'W_{PF}' 'W_{Act}' 'R_{PF}' 'R_{Act}'};
    title = strcat('\multicolumn{1}{c}{', title, '}');
    p.writeln('\setlength{\tabcolsep}{5pt}');
    p.table('', title, body, 'l r r l r r r r r r');
end
