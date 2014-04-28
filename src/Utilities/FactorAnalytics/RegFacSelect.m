% this function fits cross sectional regression between return and factors, and perform factor selection based on input criterias; 
function [beta, epsilon, std_b, R2, mse, yhat, adjR2, R2contrib, facPF, selectidx] = RegFacSelect(ret, factors, varargin)
    option.weight = [];
    option.method = []; % selection method: 'backward', 'forward', 'all'
    option.constidx = 1;
    option.riskfacidx = []; % this is the index of risk factors that have to be chosen
    option.maxfac = numel(factors);
    option = Option.vararginOption(option, {'weight','method','constidx','riskfacidx','maxfac'}, varargin{:});
    
    if isa(option.weight, 'myfints')
        FTSASSERT(isaligneddata(ret, option.weight), 'ret and weight not aligned');
        option.weight(isnan(option.weight)) = 0;
    end
    FTSASSERT(isaligneddata(ret, factors{:}), 'ret and factors not aligned');
    
    allidx = find(~ismember([1:numel(factors)], option.riskfacidx));
    allidx(allidx == option.constidx) = [];
    nfactor = numel(factors);
    stop = 0; % the signal for stopping the factor selection process
    switch lower(option.method)
        case 'forward'
            selectidx = [];
            bestR2 = 0;
            while stop == 0
                poolidx = allidx(~ismember(allidx, selectidx));
                newpickidx = [];
                for i = 1:numel(poolidx)
                    tempselidx = [poolidx(i), selectidx];
                    allselidx = [option.constidx, tempselidx, option.riskfacidx];
                    tempfac = factors(allselidx);
                    [tempbeta, ~, ~, ~, ~, ~, ~, R2contrib] = csregress(ret, tempfac);
                    tstat = nanmean(tempbeta)./nanstd(tempbeta).*sqrt(nansum(~isnan(tempbeta)));
                    tempR2 = nansum(R2contrib(:,ismember(allselidx, tempselidx)),2);
                    if nanmean(tempR2) >= bestR2 % && all(tstat(ismember(allselidx, tempselidx)) >= 1.5)
                        bestR2 = nanmean(tempR2);
%                         best_T = avg_T;
                        newpickidx = poolidx(i);
                    end
                end
                selectidx = sort([newpickidx, selectidx]);
                if numel(selectidx) == option.maxfac || isempty(newpickidx)
                    stop = 1;
                end
            end
        case 'backward'
            selectidx = allidx;
            while stop == 0
                allselidx = [option.constidx, selectidx, option.riskfacidx];
                tempfac = factors(allselidx);
                tempbeta = csregress(ret, tempfac);
                tstat = nanmean(tempbeta)./nanstd(tempbeta).*sqrt(nansum(~isnan(tempbeta)));
                if all(tstat(ismember(allselidx, selectidx)) >= 1.5)
                    break;
                else % drop the factors whose t-stat is lower than 1.5 and has the smallest among others
                    min_t = min(tstat(ismember(allselidx, selectidx)));
                    selectidx(tstat(ismember(allselidx, selectidx)) == min_t) = [];
                end
            end
        otherwise
            error('invalid selection method input');
    end
    selectidx = sort(selectidx);    
    finalidx = [option.constidx, selectidx, option.riskfacidx];
    finalfac = factors(finalidx);
    [finalbeta, epsilon, finalstd_b, R2, mse, yhat, adjR2, R2contrib, tmpfacPF] = csregress(ret, finalfac);
    
    beta = myfints(ret.dates, nan(numel(ret.dates), nfactor));
    std_b = myfints(ret.dates, nan(numel(ret.dates), nfactor));
    facPF = cell(1, nfactor);
    beta(:,finalidx) = fts2mat(finalbeta);
    std_b(:,finalidx) = fts2mat(finalstd_b);
    facPF(finalidx) = tmpfacPF;
end