function [modelid_check, factorid_check] = GetFactorSummary(o_parent, savepath, strategyid, opt)
% generate a excel file with factor summaries

if nargin < 2
    
    filename = 'FA_Summary';
    facCheckfilename = 'FA_Summary.pdf';
else
    filename = ['FA_Summary_' strategyid];
    facCheckfilename = [savepath 'FA_Summary_' strategyid];
end


colname = {'ModelSubmodel','NeutralStyle','Factor','Style','Coverage(TTM)','AutoCorr', 'mean(IC)', 'sigma(IC)', 'IR(IC)', 'min(IC)', 'MDD(IC)', 'mean(FacRtn)', 'sigma(FacRtn)', 'IR(FacRtn)', 'min(FacRtn)', 'MDD(FacRtn)', 'DispersionChange', 'LiquidRtn', 'cum(FacRtn)', ['Latest 3M cummulative return <' num2str(opt.cumrtn3M) ], ['Latest 3M monthly return <' num2str(opt.rtn3M)], ['Latest 1M return <' num2str(opt.rtn1M)], ['Latest 3M liquid return <' num2str(opt.liquidrtn3M)], ['Coverage change >' num2str(opt.cvgchg) ], ['Autocorrelation change >' num2str(opt.autocorrchg) ], ['Dispersion Change >' num2str(opt.despchg) ], ['Mean factor value Change >' num2str(opt.facmeanchg)], ['Median factor value Change >' num2str(opt.facmedianchg) ], 'Factor return downcrossing', 'CheckFlag' };
checkReason = colname(20:29);
n_obj = numel(o_parent);
nStats = numel(o_parent{1}.periodstatistics)+1;

for i = 1:nStats
    set(0, 'DefaultFigureVisible', 'off');
    figfmt = 'height=0.8cm,width=1.5cm';
    factorid = [];
    cumrtn3mv = [];
    rtn3mv = [];
    rtn1mv = [];
    liquidrtn3mv =[];
    cvgv = [];
    dispersev = [];
    downcrossv = [];
    facmeanchgv= [];
    facmedianchgv = [];
    autocorrchgv = [];
    checkNum = 0;
    body = [];
    for obj = 1:n_obj
        o = o_parent{obj};
        if i > 1
            stats = o.periodstatistics{i-1}.statistics;
            sheetname = o.periodstatistics{i-1}.name;
        else
            stats = o.statistics;
            sheetname = 'statistics_whole';
        end
        
        facname = cell(1,numel(stats));
        for j = 1:numel(stats), facname{j} = stats{j}.facname; end
        nFactor = size(stats,1);
        style = nan(nFactor,1);
        
        factorid = [factorid; facname'];
        if FactorAnalyzer.isFactorId(facname)
            facstruct = LoadFactorInfo(facname, 'MatlabFunction,FactorTypeId');
            classname = facstruct.MatlabFunction;
            style = facstruct.FactorTypeId;
            if ~iscell(classname), classname = {classname}; end
            for j = 1:nFactor, facname{j} = [facname{j}, ' - ' classname{j}]; end
        end
        
        facname = reshape(facname,[numel(facname),1]);
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
        liquidFR = nan(nFactor,1);
        disperseChg = nan(nFactor,1);
        facmeanChg = nan(nFactor,1);
        facmedianChg = nan(nFactor,1);
        cumFR = nan(nFactor,1);
        checkFlag = nan(nFactor,1);
        cumrtn3m_check = nan(nFactor,1);
        rtn3m_check = nan(nFactor,1);
        rtn1m_check = nan(nFactor,1);
        liquidrtn3m_check = nan(nFactor,1);
        cvg_check = nan(nFactor,1);
        disperse_check = nan(nFactor,1);
        downcross_check = nan(nFactor,1);
        meanfacval_check = nan(nFactor,1);
        medianfacval_check = nan(nFactor,1);
        autocorr_check = nan(nFactor,1);
        
        for j = 1:nFactor
            tempstat = stats{j};
            cvg(j) = nanmean(tempstat.coverage(max(end-11,1):end,:));
            ac(j) = nanmean(tempstat.autocorr);
            meanIC(j) = nanmean(tempstat.IC{1});
            sigmaIC(j) = nanstd(tempstat.IC{1});
            IRIC(j) = tempstat.IRIC(1);
            minIC(j) = nanmin(tempstat.IC{1},[],1);
            mddIC(j) = nanmin(FtsDrawDown(tempstat.IC{1}),[],1);
            meanFR(j) = nanmean(tempstat.LS{1});
            sigmaFR(j) = nanstd(tempstat.LS{1});
            IRFR(j) = tempstat.IRLS(1);
            minFR(j) = nanmin(tempstat.LS{1},[],1);
            mddFR(j) = nanmin(FtsDrawDown(tempstat.LS{1}),[],1);
            cumLS = cumsum(tempstat.LS{1});
            cum6mLS = cumsum(tempstat.LS{1}(end-5:end));
            cumFR(j) = fts2mat(cumLS(end));
            tempstat.liquidrtn = cssum(tempstat.liquidrtn(:,opt.liquidqt));
            liquidFR(j) = fts2mat(tempstat.liquidrtn(end));
            dispersionchg = bsxfun(@rdivide,bsxfun(@minus,tempstat.dispersion,lagts(tempstat.dispersion,1)),lagts(tempstat.dispersion,1));
            meanfacvalchg = bsxfun(@rdivide,bsxfun(@minus,tempstat.meanfacval,lagts(tempstat.meanfacval,1)),lagts(tempstat.meanfacval,1));
            medianfacvalchg = bsxfun(@rdivide,bsxfun(@minus,tempstat.medianfacval,lagts(tempstat.medianfacval,1)),lagts(tempstat.medianfacval,1));
            cvgchg = bsxfun(@minus, tempstat.coverage, lagts(tempstat.coverage,1));
            acchg = bsxfun(@minus, tempstat.autocorr, lagts(tempstat.autocorr,1));
            disperseChg(j) = fts2mat(dispersionchg(end));
            facmeanChg(j) = fts2mat(meanfacvalchg(end));
            facmedianChg(j) = fts2mat(medianfacvalchg(end));
            
            rtnfts = tempstat.LS{1};
            martnfts = ftsmovfun(rtnfts, 6, @(x)(nanmean(x,1)));
            stdrtnfts = ftsmovfun(rtnfts, 6, @(x)(nanstd(x,1)));
            downbandfts = martnfts - opt.rtnbandwidth*stdrtnfts;
            
            % define the criteria here
            cumrtn3m_check(j) = nansum(rtnfts(end-2:end))<= opt.cumrtn3M;
            rtn3m_check(j) = nansum(rtnfts(end-2:end)>opt.rtn3M)== 0 ;
            rtn1m_check(j) = fts2mat(rtnfts(end)) <= opt.rtn1M;
            liquidrtn3m_check(j) = nansum(tempstat.liquidrtn(end-2:end) > opt.liquidrtn3M)==0;
            cvg_check(j) = fts2mat(cvgchg(end)) > opt.cvgchg;
            autocorr_check(j) = fts2mat(acchg(end)) > opt.autocorrchg;
            disperse_check(j) = abs(disperseChg(j)) > opt.despchg;
            meanfacval_check(j) = abs(facmeanChg(j)) > opt.facmeanchg;
            medianfacval_check(j) = abs(facmedianChg(j)) > opt.facmedianchg;
            downcross_check(j) = fts2mat((rtnfts(end) - downbandfts(end))) < 0;
            
            checkvec = [cumrtn3m_check(j) rtn3m_check(j)  rtn1m_check(j)  liquidrtn3m_check(j)  cvg_check(j) autocorr_check(j) disperse_check(j) meanfacval_check(j) medianfacval_check(j) downcross_check(j)];
            checkFlag(j) = sum(checkvec, 2) > 0 ;
            cumrtn3mv = [cumrtn3mv; cumrtn3m_check(j)];
            rtn3mv = [rtn3mv; rtn3m_check(j)];
            rtn1mv = [rtn1mv; rtn1m_check(j)];
            liquidrtn3mv = [liquidrtn3mv; liquidrtn3m_check(j)];
            cvgv = [cvgv; cvg_check(j)];
            dispersev = [dispersev; disperse_check(j)];
            facmeanchgv = [facmeanchgv; meanfacval_check(j)];
            facmedianchgv = [facmedianchgv; medianfacval_check(j)];
            downcrossv = [downcrossv; downcross_check(j)];
            autocorrchgv = [autocorrchgv; autocorr_check(j)];
            
            tempbody = cell(1,4);
            if checkFlag(j) == 1 && i==1
                checkNum = checkNum + 1;
                tempbody{1,1} = o.univname;
                tempbody{1,2} = strrep(facname{j},'_', '\_');
                [~,bb] = find(checkvec);
                tempbody{1,3} = checkReason{bb(1)};
                tabplot(fts2mat(cumLS), num2str(checkNum, 'AN%3.3d'));
                tabplot(fts2mat(cum6mLS), num2str(checkNum, 'AN6m%3.3d'));
                tempbody{1,4} = ['\raisebox{-0.2cm}{\includegraphics[' figfmt ']{' num2str(checkNum, 'AN%3.3d') '}}'];
                tempbody{1,5} = ['\raisebox{-0.2cm}{\includegraphics[' figfmt ']{' num2str(checkNum, 'AN6m%3.3d') '}}'];
                body = [body; tempbody];
            end
            
        end
        
        content = num2cell([style, cvg, ac, meanIC, sigmaIC, IRIC, minIC, mddIC, meanFR, sigmaFR, IRFR, minFR, mddFR, disperseChg, liquidFR, cumFR, cumrtn3m_check,rtn3m_check,rtn1m_check,liquidrtn3m_check,cvg_check, autocorr_check, disperse_check,meanfacval_check, medianfacval_check, downcross_check, checkFlag]);
        univname = repmat({o.univname},nFactor,1);
        neutralstyle = repmat(stats{1}.neutralstyle,nFactor,1);
        if obj == 1
            data = [colname; [univname,neutralstyle,facname,content]];
        else
            data = [data; [univname,neutralstyle,facname,content]];
        end
    end
    xlswrite([savepath,filename],data,sheetname);
    data = data(2:end,:);
    modelid_check = data(cell2mat(data(:,end))==1, 1);
    factorid_check = factorid(cell2mat(data(:,end))==1);
    checkstat = [cumrtn3mv rtn3mv rtn1mv  liquidrtn3mv cvgv autocorrchgv dispersev facmeanchgv facmedianchgv downcrossv];
    if i == 1
        title = {'model' 'factorID-factorname' 'checking reason' 'cumRtn' 'cum6Mrtn'};
        p = PDFDoc(facCheckfilename);
        p.table(['Factors need to be investigated on ' strrep(strategyid, '_', '\_')], title, body, 'llllc');
        p.run;
        system('del AN???.pdf > nul');
        system('del AN6m???.pdf > nul');
    end
    
end
end % of function

%function tabplot(r, outsample_r, outsample_color, fname)
function tabplot(r, fname)
figure
set(gcf, 'PaperUnits', 'centimeters', ...
    'PaperSize', [2 1], ...
    'PaperPosition', [-0.58 -0.38 2.8 1.48]);
if numel(r) > 1
    plot(r, 'linewidth', 1);
    %         hold on
    %         plot(outsample_r, 'linewidth', 1, 'color', outsample_color);
    
    botbnd = min(r)-0.005;
    upbnd = max(r) + 0.005;
    set(gca, 'XLim', [1 numel(r)], 'YLim', [botbnd upbnd]);
end
set(gca, 'box', 'off', 'visible', 'off', 'color', 'none');
saveas(gcf, [fname '.pdf']);
close
end