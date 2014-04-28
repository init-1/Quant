function [o_old, o_new] = CalcStatistics(o, startdate, enddate, varargin)        
    option.gicslevel = 1;
    option.facOrAlpha = NaN; % it can be a myfints (means external signals/alphas) or a cell array of factorid (means selected factors), default is NaN (means all factors in object)
    option.isnormalize = 1; % 1: to normalize the factors, 0: not to normalize the factors
    option.neutralstyle = {'gics','ctry'};% the styles to neutralize and show on the report
    
    option.custstyle.name = {}; % customized neutralization style, has to be a struct with field: name - a cell array of names in string
    option.custstyle.data = {}; % customized neutralization style, has to be a struct with field: name - a cell array of myfints with numeric data
    option.custuniv.name = {}; % customized security universe, has to be a struct with field: name - the string name of the universe
    option.custuniv.data = {}; % customized security universe, has to be a struct with field: data - a myfints with numeric data
    option.custplot = {'ByGICS', 'LongShort', 'ScoreByMcap', 'RtnByMcap', 'ScoreByLiq', 'RtnByLiq'}; % customized choice of plots: a cell array
    option.savepath = '.\';% save path of the report
    option.fileprefix = 'FA';
    option.isplot = 1; %Generate the pdfs
    
    option = Option.vararginOption(option, {'gicslevel','facOrAlpha','isnormalize','neutralstyle','custstyle','custuniv','custplot','savepath','fileprefix','isplot'}, varargin{:});
    
    switch upper(o.freq)
        case 'W'
            ann_adj = 52;
        case 'M'
            ann_adj = 12;
        case 'Q'
            ann_adj = 4;
        case 'D'
            ann_adj = 252;
        otherwise
            error('invalid frequency inputed');
    end
    
    VIX = LoadIndexItemTS('CBOEVIX', 'D001700003', datestr(datenum(startdate) - 30, 'yyyy-mm-dd'), datestr(datenum(enddate), 'yyyy-mm-dd'));
    VIX_ema = ftsema(VIX, 5, 1);
    
    o_old = o;
    
    %% customized universe
    if ~isempty(option.custuniv.data)
        o.univname = option.custuniv.name{:};
        o.bmhd = option.custuniv.data;
    end
    
    %% customized neutralization style
    neutralstyle = option.neutralstyle;
    neutralfts = cell(size(neutralstyle));
    neutrallevel = cell(size(neutralstyle));
    for j = 1:numel(neutralfts)
        neutralfts{j} = o.(neutralstyle{j});
        if strcmpi(option.neutralstyle{j}, 'gics')
            neutrallevel{j} = option.gicslevel;
        else
            neutrallevel{j} = 'customized';
        end
    end
    if ~isempty(option.custstyle.name)
        assert(sum(ismember(option.neutralstyle, option.custstyle.name)) == 0, 'user customized neutral style name overlap with existing style name'); 
        neutralstyle = [neutralstyle, option.custstyle.name];
        neutralfts = [neutralfts, option.custstyle.data];
        neutrallevel = [neutrallevel, repmat({'customized'},size(option.custstyle.name))];
    end
    
    %% Start calcualtion
    dates = o.bmhd.dates;
    dates = dates(dates >= datenum(startdate) & dates <= datenum(enddate));
    VIX_ema = aligndates(VIX_ema, dates);
    
    [o.factorts{:}, neutralfts{:}, o.fwdret, o.gics, o.mcap, o.brcost,o.adv, o.fwdretByDay{:}] = ...
        alignto(o.bmhd, o.factorts{:}, neutralfts{:}, o.fwdret, o.gics, o.mcap, o.brcost,o.adv, o.fwdretByDay{:});

    if isa(option.facOrAlpha,'myfints') % in case of input alpha from outside
        nfactor = 1;
        alpha = option.facOrAlpha;
        alpha = alignto(o.bmhd, alpha);
        tmpfactorts = {alpha};
        facname = {'Alpha'};
        ishigh = 1; 
    elseif isa(option.facOrAlpha,'struct') % in case of input structures of myfints and their names
        nfactor = numel(option.facOrAlpha.name);
        tmpfactorts = option.facOrAlpha.data;
        [tmpfactorts{:}] = alignto(o.bmhd, tmpfactorts{:});
        facname = option.facOrAlpha.name;
        assert(numel(tmpfactorts) == numel(facname), 'number of input factors and names do not match');
        ishigh = ones(size(facname));
    elseif iscell(option.facOrAlpha) % in case of a list of selected factors
        selectidx = ismember(o.facinfo.name, option.facOrAlpha);
        nfactor = nansum(selectidx);
        tmpfactorts = o.factorts(selectidx);
        facname = o.facinfo.name(selectidx);
        ishigh = o.facinfo.ishigh(selectidx);
    elseif isnan(option.facOrAlpha); % in case of running all factors
        nfactor = numel(o.factorts);
        tmpfactorts = o.factorts;
        facname = o.facinfo.name;
        ishigh = o.facinfo.ishigh;
    end

    if FactorAnalyzer.isFactorId(facname)
        facstruct = LoadFactorInfo(facname, 'MatlabFunction');
        mnemonic = facstruct.MatlabFunction;
        if ischar(mnemonic), mnemonic = {mnemonic}; end
    else
        mnemonic = repmat({''}, size(facname));
    end

    [ndate, nstock] = size(o.bmhd);
    o.statistics = cell(nfactor,1);
    for i = 1:nfactor
        %% Step 1 - Calculation for each factor
        disp(['working on # ', num2str(i), ' factor']);
        nstyle = numel(neutralstyle);

        factor_neutral = cell(1, nstyle);
        factor_neutral_quintile = cell(1, nstyle);
        LS = cell(1, nstyle);
        Long = cell(1, nstyle);
        Short = cell(1, nstyle);
        IC = cell(1, nstyle);
        T_LS = nan(1, nstyle);
        T_IC = nan(1, nstyle);
        IRLS = nan(1, nstyle);
        IRIC = nan(1, nstyle);
        mean_IC = nan(1, nstyle);
        mean_LS = nan(1, nstyle);
        mean_Long = nan(1, nstyle);
        mean_Short = nan(1, nstyle);
%                 LSByDay = cell(numel(o.fwdretByDay), nstyle);
%                 ICByDay = cell(numel(o.fwdretByDay), nstyle);
        ContribByRtn = nan(nstock, nstyle);

        ShortScoreByMcap = nan(o.nbucket, nstyle);
        ShortScoreByBrCost = nan(o.nbucket, nstyle);                
        FacPFScoreByAdv = nan(o.nbucket, nstyle);                

        ShortRtnByMcap = nan(o.nbucket, nstyle);
        ShortRtnByBrCost = nan(o.nbucket, nstyle);
        FacPFRtnByAdv = nan(o.nbucket, nstyle);   
        FacPFRtnByQuintile = nan(o.nbucket,nstyle);

        IRICByGICS = nan(10, nstyle);
        numByGICS = nan(10, 1);
        
        Ctry = LoadSecInfo(fieldnames(o.bmhd,1),{'country'},'','',0);
        uniqctry = unique(Ctry.country);
        nctry = numel(uniqctry);
        if nctry == 1
            IRICByCtry = nan(nctry+1, nstyle);
            numByCtry = nan(nctry+1, 1);  
        end
            
%         tmpfactorts{i} = ishigh(i)*tmpfactorts{i}; 
        for j = 1:nstyle           
            f = ishigh(i)*tmpfactorts{i};
            f(isnan(fts2mat(o.bmhd))) = NaN;
            if option.isnormalize == 1 % when isnormalize = 1
                f = normalize(f, 'method', 'norminv', 'weight', o.bmhd, 'GICS', neutralfts{j}, 'level', neutrallevel{j});                
            end
            factor_neutral{j} = f;

%                     for fs=1:numel(filterstr)
%                         level = 8-length(num2str(filterstr(fs)));
%                         g = floor(gics_./10^level);
%                         f(g==filterstr(fs)) = nan;                                
%                     end                
            [LS{j}, ~,~, facPF, longPF, shortPF] = factorPFRtn(factor_neutral{j}, o.fwdret, o.bmhd); 
            IC{j} = csrankcorr(factor_neutral{j}, o.fwdret);
            facPFContrib = facPF.*o.fwdret;
            %longPFContrib = longPF.*o.fwdret;
            shortPFContrib = (shortPF + o.bmhd).*o.fwdret;
%                     for k = 1:numel(o.fwdretByDay)
%                         [TempLS, ~, ~, ]= factorPFRtn(factor_neutral{j}, o.fwdretByDay{k}, o.bmhd);
%                         LSByDay{k,j} = TempLS(:,1);
%                         ICByDay{k,j} = csrankcorr(factor_neutral{j}, o.fwdretByDay{k});
%                     end   

            
            Long{j} = cssum((longPF - o.bmhd).*o.fwdret);
            Short{j} = cssum((shortPF + o.bmhd).*o.fwdret);
            
            mean_LS(j) = nanmean(LS{j})*ann_adj;
            mean_Long(j) = nanmean(Long{j})*ann_adj;
            mean_Short(j) = nanmean(Short{j})*ann_adj;
            IRLS(j) = nanmean(LS{j})./nanstd(LS{j})*sqrt(ann_adj);
            T_LS(j) = IRLS(j)*sqrt(ndate);

            mean_IC(j) = nanmean(IC{j});
            IRIC(j) = nanmean(IC{j})./nanstd(IC{j})*sqrt(ann_adj);
            T_IC(j) = IRIC(j)*sqrt(ndate);

            % calculate the return contribution curve
            stockContrib = nanmean(facPFContrib, 1)*ann_adj;
            ContribByRtn(:,j) = sort(stockContrib);
            
            % Divide stocks into buckets based on nomalized factor score
            % before running csRankPrc, Set the factor score to nan for stocks 
            % having zero normalized score(having null raw factor values)             
            
            temp_facscore = factor_neutral{j};
            temp_facscore(temp_facscore == 0) = nan;            
            fac_prc = csRankPrc(temp_facscore,'ascend');
            interval = 100./o.nbucket;
            fac_prc(:,:) = ceil(fts2mat(fac_prc)./interval);
            factor_neutral_quintile{j} = fac_prc;

            for m = 1:(o.nbucket)
                % calculate the average score(short side only) sorted by mcap bucket
                ShortScoreByMcap(m,j) = nanmean(meanif(factor_neutral{j}, 2, fts2mat(o.mcap) == m & fts2mat(factor_neutral{j} < 0)));
                % calculate the total return contribution(short side only) sorted by mcap bucket
                ShortRtnByMcap(m,j) = nanmean(sumif(shortPFContrib, 2, fts2mat(o.mcap) == m))*ann_adj;

                % calculate the average score(short side only) sorted by BorrowCost bucket
                ShortScoreByBrCost(m,j) = nanmean(meanif(factor_neutral{j}, 2, fts2mat(o.brcost) == m & fts2mat(factor_neutral{j} < 0)));                        
                % calculate the total return contribution(short side only) sorted by BorrowCost bucket
                ShortRtnByBrCost(m,j) = nanmean(sumif(shortPFContrib, 2, fts2mat(o.brcost) == m))*ann_adj;

                % calculate the average score(long score minus short score) sorted by Liquidity bucket
                FacPFScoreByAdv(m,j) = nanmean(meanif(abs(factor_neutral{j}), 2, fts2mat(o.adv) == m));

                % calculate the total return contribution(long minus short) sorted by Liquidity bucket
                FacPFRtnByAdv(m,j) = nanmean(sumif(facPFContrib, 2, fts2mat(o.adv) == m))*ann_adj;
                
                % calculate the total return contribution(long minus short) sorted by Liquidity bucket
                FacPFRtnByQuintile(m,j) = nanmean(meanif(o.fwdret, 2, fts2mat(factor_neutral_quintile{j}) == m))*ann_adj;
            end

            % calculate stat by sector
            for m = 1:10 
                tempfac = factor_neutral{j};
                tempret = o.fwdret;
                tempfac(floor(fts2mat(o.gics)/(10^6)) ~= 5*(m+1)) = NaN;
                tempret(floor(fts2mat(o.gics)/(10^6)) ~= 5*(m+1)) = NaN;
                IRICByGICS(m,j) = nanmean(csrankcorr(tempfac, tempret))/nanstd(csrankcorr(tempfac, tempret))*sqrt(ann_adj);
                if j == 1
                    numByGICS(m) = nanmean(nansum(floor(fts2mat(o.gics)/(10^6)) == 5*(m+1),2),1);
                end
            end
            
            % calcualte stat by country
            for m = 1:nctry
                tempfac = factor_neutral{j};
                tempret = o.fwdret;
                tempfac(:,~ismember(Ctry.country, uniqctry{m})) = NaN;
                tempret(:,~ismember(Ctry.country, uniqctry{m})) = NaN;
                IRICByCtry(m,j) = nanmean(csrankcorr(tempfac, tempret))/nanstd(csrankcorr(tempfac, tempret))*sqrt(ann_adj);
                if j == 1
                    numByCtry(m) = nanmean(nansum(~isnan(o.bmhd(:,ismember(Ctry.country, uniqctry{m}))),2));
                end
            end
        end

        % raw factor descriptive statistics
        autocorr = csrankcorr(tmpfactorts{i}, lagts(tmpfactorts{i},1,nan));
        mean_ac = nanmean(autocorr);
        coverage = myfints(o.bmhd.dates, nansum(~isnan(fts2mat(tmpfactorts{i})) & ~isnan(fts2mat(o.bmhd)),2)...
            ./nansum(~isnan(fts2mat(o.bmhd)),2), 'value');
        mean_coverage = nanmean(fts2mat(coverage));
        nonezero = myfints(o.bmhd.dates, nansum(fts2mat(tmpfactorts{i}) ~= 0 & ~isnan(fts2mat(tmpfactorts{i})) & ~isnan(fts2mat(o.bmhd)),2)...
            ./nansum(~isnan(fts2mat(o.bmhd)),2), 'value');
        mean_nonezero = nanmean(fts2mat(nonezero));
        tmpfactorts{i}(~(o.bmhd > 0)) = NaN; 
        cs_median = csmedian(tmpfactorts{i});
        toptile = uniftsfun(tmpfactorts{i}, @(x)quantile(x,0.8,2), 'value');
        bottile = uniftsfun(tmpfactorts{i}, @(x)quantile(x,0.2,2), 'value');

        % separate by risk regime
        lowidx = fts2mat(VIX_ema) < 20;
        highidx = fts2mat(VIX_ema) >= 30;
        mididx = fts2mat(VIX_ema) < 30 & fts2mat(VIX_ema) >= 20;

        regimename = {'LowVol','MidVol','HighVol'};
        regimeidx = {lowidx, mididx, highidx};
        regimeCount = cell2mat(cellfun(@(x) {nansum(x)}, regimeidx));
        nregime = numel(regimename);

        regimeICIR = nan(nregime, nstyle);
        regimeLSIR = nan(nregime, nstyle);
        regimeLS = nan(nregime, nstyle);
        regimeIC = nan(nregime, nstyle);
        for j = 1:nstyle
            for k = 1:nregime
                regimeIC(k,j) = nanmean(IC{j}(regimeidx{k},:));
                regimeLS(k,j) = nanmean(LS{j}(regimeidx{k},:))*ann_adj;
                regimeICIR(k,j) = nanmean(IC{j}(regimeidx{k},:))/nanstd(IC{j}(regimeidx{k},:))*sqrt(ann_adj);
                regimeLSIR(k,j) = nanmean(LS{j}(regimeidx{k},1))/nanstd(LS{j}(regimeidx{k},1))*sqrt(ann_adj);
            end
        end
        
        % calculate liquidity based quintile return
        qtrtn = [];
        for quintileNum = 1:5
            qtrtn = [qtrtn fts2mat(sumif(facPFContrib, 2, fts2mat(o.adv) == quintileNum))];
        end
        
        o.statistics{i}.facname = facname{i};
        o.statistics{i}.neutralstyle = neutralstyle;
        o.statistics{i}.factor_neutral = factor_neutral;
        o.statistics{i}.LS = LS;
        o.statistics{i}.Long = Long;
        o.statistics{i}.Short = Short;
        o.statistics{i}.IC = IC;
        o.statistics{i}.IRLS = IRLS;
        o.statistics{i}.IRIC = IRIC;
%                 o.statistics{i}.LSByDay = LSByDay;
        o.statistics{i}.autocorr = autocorr;
        o.statistics{i}.coverage = coverage;
        o.statistics{i}.nonezero = nonezero;
        o.statistics{i}.regimename = regimename;
        o.statistics{i}.regimeICIR = regimeICIR;
        o.statistics{i}.regimeLSIR = regimeLSIR;
        o.statistics{i}.regimeCount = regimeCount;
        
        % added for strategy factor monitor
        o.statistics{i}.liquidrtn = myfints(facPFContrib.dates, qtrtn);
        o.statistics{i}.meanfacval = csmean(tmpfactorts{i});
        o.statistics{i}.medianfacval = csmedian(tmpfactorts{i});
        o.statistics{i}.dispersion = toptile - bottile;
        
        %% Step 2 - Report
        row = 5;
        col = 2;

        % the first four graphs are fixed as Coverage, Descriptive Stat, Rolling IC and CumRtn 
        fig = MyPlot.PlotCoverage(row, col, 1, [], mean_ac, mean_coverage, mean_nonezero, autocorr, coverage, nonezero);
        MyPlot.PlotStat(row, col, 2, fig, cs_median, toptile, bottile);  
        MyPlot.PlotICIR(row, col, 3, fig, neutralstyle, mean_IC, IRIC, IC);   
        MyPlot.PlotCumRtn(row, col, 4, fig, LS, neutralstyle, IRLS);                                                       
                
        % plot 5 to 10 are customized
        for p = 5:10
            pos = p;
            switch option.custplot{p-4}
                case 'ByGICS'
                    MyPlot.PlotByGICS(row, col, pos, IRICByGICS, numByGICS, neutralstyle);
                case 'ByCtry'
                    MyPlot.PlotByCtry(row, col, pos, IRICByCtry, numByCtry, neutralstyle, uniqctry);
                case 'ByRegime'
                    MyPlot.PlotByRegime(row, col, pos, regimeLSIR, regimename, neutralstyle);
                case 'LongShort'
                    MyPlot.PlotLongShort(row, col, pos, mean_Long, mean_Short, mean_LS, neutralstyle);                
                case 'StockRtn'
                    MyPlot.PlotStockRtn(row, col, pos, ContribByRtn, neutralstyle);
                case 'RtnByMcap'
                    MyPlot.PlotRtnByMcap(row, col, pos, ShortRtnByMcap, neutralstyle);
                case 'ScoreByMcap'
                    MyPlot.PlotScoreByMcap(row, col, pos, ShortScoreByMcap, neutralstyle);
                case 'RtnByCost'
                    MyPlot.PlotRtnByCost(row, col, pos, ShortRtnByBrCost, neutralstyle);
                case 'ScoreByCost'
                    MyPlot.PlotScoreByCost(row, col, pos, ShortScoreByBrCost, neutralstyle);
                case 'RtnByLiq'
                    MyPlot.PlotRtnByLiq(row, col, pos, FacPFRtnByAdv, neutralstyle);
                case 'ByQuintile'
                    MyPlot.PlotRtnByQuintile(row, col, pos, FacPFRtnByQuintile, neutralstyle);
                case 'ScoreByLiq'
                     MyPlot.PlotScoreByLiq(row, col, pos, FacPFScoreByAdv, neutralstyle);
                otherwise
                    disp('warning: the customized plot: ',option.custplot{p-4},' is not valid');
            end
        end

        % title of report
        if ~ismember('univname', fieldnames(o)),
            univ = 'Not Specified';
        else
            univ = o.univname;
        end
        nstockrpt = round(nanmean(nansum(~isnan(o.bmhd),2)));
        axes('Position', [0, 0.98, 1, 0.06], 'visible', 'off');
        text(0.5,0,['\bf Report of Factor: ',facname{i},'(',mnemonic{i}, '), Univ: ',univ, ', Names:', num2str(nstockrpt),', Freq: ', o.freq], 'HorizontalAlignment', 'center');

        % save report as PDF
        saveas(fig, [option.savepath, option.fileprefix, '-', facname{i}, '.pdf'], 'pdf');

        close;    
    end
    
    o_new = o;
    o_old.statistics = o.statistics;
end

