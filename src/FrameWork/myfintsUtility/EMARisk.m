classdef RiskEMA < RiskModel
    methods
        function o = RiskEMA(isLive, dates, aggId)
            o = o@RiskModel(isLive, dates, aggId);
            o.name = 'EMA';
        end
    end
    
    methods(Access = protected)
        function o = load(o)
            if o.owner.isLive
                switch o.aggid
                    case {'0064990200','00053','000524248','000530824','0069KLD400'}
                        emid = 'D001500088';
                    case '0064990300'
                        emid = 'D001500092';
                    case '0064903600'
                        emid = 'D001500105';
                    otherwise
                        emid = 'D001500091';
                end
            else
                emid = 'D001500091';
            end
            
            seclist = sprintf(',%s', o.secids);
            
            %%% Load exposures
            secexp = [];
            aggexp = [];
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t),'yyyy-mm-dd');
                DB('datainterfaceserver');
                ret = DB.runSql('dataqa.api.usp_RiskModel', emid, seclist(2:end), tstr, tstr);
                secexp = stackStruct(secexp, ret, o.dates(t));

                indexid = ['X' o.aggid];
                try
                    aggexp = DB.runSql('dataqa.api.usp_RiskModel', emid, indexid, tstr, tstr);
                catch  %#ok<CTCH>
                    slist = DB.runSql(['select secid from ModelDB.emrisk.SecMapping where identifier in '...
                            '(select ProxyIdentifier from ModelDB.emrisk.SecMapping where SecId=' indexid ')']);
                    ret = DB.runSql('dataqa.api.usp_RiskModel', emid, slist, tstr, tstr);
                end
                aggexp = stackStruct(aggexp, ret, o.dates(t));
            end
            
            % pack to xts
            secexp = mat2xts(secexp.date, secexp.val, secexp.secid, secexp.fname);
            aggexp = mat2xts(aggexp.date, aggexp.val, aggexp.secid, aggexp.fname);
            weight = o.owner.attribute('benchmark');
            gics   = o.owner.attribute('GICS');
            [secexp, aggexp, weight, gics] = aligndates(secexp, aggexp, weight, gics);
            [secexp, aggexp, weight, gics] = alignfields(secexp, aggexp, weight, gics, 1);  % ony align 3rd dimension
            [secexp, aggexp] = alignfields(secexp, aggexp, 2);  % ony align 3rd dimension
            
            % some calculation here
            facflds = fieldnames(secexp,1,2);
            facflds = facflds(strncmp(facflds, 'Factor_', 7));
            
            beta = bsxfun(@times, secexp, aggexp);
            beta = uniftsfun(beta(:,:,facflds), @(x)nansum(x,3), {'',{'SpecificRisk'}}) ...
                 + bsxfun(@times, secexp(:,:,'SpecificRisk').*secexp(:,:,'SpecificRisk'), weight);
            beta = chfield(beta, 'SpecificRisk', 'R2', 2);   % make plus plausible
            beta = 1-secexp(:,:,'R2') + secexp(:,:,'R2') .* beta;
            allflds = [facflds; 'SpecificRisk'];
            beta = beta ./ uniftsfun((aggexp(:,:,allflds) .* aggexp(:,:,allflds)), @(x)nansum(x,3), {'',{'R2'}});
            beta(beta < 0.5) = 0.5;
            beta(beta > 2) = 2;
            secexp(:,:,'R2') = beta;
            
            allflds = [facflds, 'R2'];
            for i = 1:length(allflds)
                fts = squeeze(secexp(:,:,allflds(i)));
                nanidx = isnan(fts);
                fts = neutralize(fts, gics, @(x)repmat(mean(x,2),size(x,2),1), 1);
                fts(nanidx) = nan;
                secexp(:,:,allflds(i)) = fts2mat(fts);
            end
            
            if strcmp(o.aggid, '0064899903')
                sid = '0058@ISHAR451';
                if isfield(secexp, sid, 1)
                    secexp(:,sid,:) = nanmean(fts2mat(secexp), 2);
                end
            end
            o.beta = squeeze(secexp(:,:,'R2'));
            o.exposure = secexp(:,:,facflds);
            o.faccov = xts(o.dates, zeros(length(o.dates), length(facflds), length(facflds)), facflds, facflds);
            o.specrisk = squeeze(secexp(:,:,'SpecificRisk'));
        end
    end
end

function ret = stackStruct(oldst, newst, date)
    if isempty(oldst)
        ret.val = [];
        ret.fname = {};
        ret.secid = {};
    else
        ret = oldst;
    end
    
    flds = fieldnames(newst);
    N = length(newst.secid);
    for i = 2:length(flds)
        ret.val   = [ret.val; newst.(flds{i})]; %#ok<*AGROW>
        ret.fname = [ret.fname; repmat(flds(i), N, 1)];
        ret.secid = [ret.secid; newst.secid];
    end
    ret.date = repmat(date, length(val), 1);
end
