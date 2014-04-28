classdef RiskEMA < RiskModel
    methods
        function o = RiskEMA(aggid, dates, isLive)
            o = o@RiskModel(aggid, dates, isLive);
        end
    end
    
    methods(Access = protected)
%         function o = load_(o)
%             if o.owner.isLive
%                 switch o.aggid{1}
%                     case {'0064990200','00053','000524248','000530824','0069KLD400'}
%                         emid = 'D001500088';
%                     case '0064990300'
%                         emid = 'D001500092';
%                     case '0064903600'
%                         emid = 'D001500105';
%                     otherwise
%                         emid = 'D001500091';
%                 end
%             else
%                 emid = 'D001500091';
%             end
% 
%             sids = o.owner.getUniverse;
%             seclist = sprintf(',E%s', sids{:});
%             
%             %%% Load exposures
%             secexp = [];
%             aggexp = [];
%             for t = 1:length(o.dates)
%                 tstr = datestr(o.dates(t),'yyyy-mm-dd');
%                 DB('QuantTrading');
%                 ret = DB.runSql(['datainterfaceserver.dataqa.api.usp_RiskModel '''...
%                       emid ''',''' seclist(2:end) ''',''' tstr ''',''' tstr '''']);
%                 secexp = stackStruct(secexp, ret, o.dates(t));
% 
%                 indexid = ['X' o.aggid{1}];
%                 try
%                     ret = DB.runSql(['datainterfaceserver.dataqa.api.usp_RiskModel '''...
%                              emid ''',''' indexid ''',''' tstr ''',''' tstr '''']);
%                 catch  %#ok<CTCH>
%                     slist = DB.runSql(['select secid from ModelDB.emrisk.SecMapping where identifier in '...
%                             '(select ProxyIdentifier from ModelDB.emrisk.SecMapping where SecId=''' indexid ''')']);
%                     ret = DB.runSql(['datainterfaceserver.dataqa.api.usp_RiskModel '''...
%                           emid ''',''' slist ''',''' tstr ''',''' tstr '''']);
%                 end
%                 aggexp = stackStruct(aggexp, ret, o.dates(t));
%             end
%             
%             % pack to xts
%             secexp = mat2xts(secexp.date, secexp.val, secexp.secid, secexp.fname);
%             aggexp = mat2xts(aggexp.date, aggexp.val, aggexp.secid, aggexp.fname);
%             weight = o.owner(['X' o.aggid{1}]);
%             gics   = LoadQSSecTS(fieldnames(weight,1), 913, datestr(weight.dates(1),'yyyy-mm-dd'), datestr(weight.dates(end),'yyyy-mm-dd'));
%             [secexp, aggexp, weight, gics] = aligndates(secexp, aggexp, weight, gics, o.dates);
%             [secexp, weight, gics] = alignfields(secexp, weight, gics, 1);  % ony align 2rd dimension
%             [secexp, aggexp] = alignfields(secexp, aggexp, 2);  % ony align 3rd dimension
%             
%             % some calculation here
%             fldFactors = fieldnames(secexp,1,2);
%             fldFactors = fldFactors(strncmp(fldFactors, 'Factor_', 7));
%             fldSpecificRisk = 'Residual_Variance';
%             fldR2 = 'R_Squared';
%             
%             beta = bsxfun(@times, secexp(:,:,fldFactors), aggexp(:,:,fldFactors));
%             beta = uniftsfun(beta, @(x)nansum(x,3)) ...
%                  + secexp(:,:,fldSpecificRisk) .* secexp(:,:,fldSpecificRisk) * (weight./100);
%             tmp = aggexp(:,:,[fldFactors; fldSpecificRisk]);
%             beta = bsxfun(@rdivide, beta, uniftsfun(tmp .* tmp, @(x)nansum(x,3)));
%             beta = 1 - secexp(:,:,fldR2) + secexp(:,:,fldR2) .* beta;
%             beta(beta < 0.5) = 0.5;
%             beta(beta > 2) = 2;
%             secexp(:,:,fldR2) = beta;  % we use fldR2 store beta
%             
%             flds = [fldFactors; fldR2];
%             for i = 1:length(flds)
%                 fts = secexp(:,:,flds(i));
%                 fts = o.owner.applyUniverse(fts);
%                 nanidx = isnan(fts);
%                 fts = neutralize(fts, gics, @(x)repmat(nanmean(x,2), 1, size(x,2)), 1);
%                 fts(nanidx) = nan;
%                 secexp(:,:,flds(i)) = fts;
%             end
%             
%             if strcmp(o.aggid{1}, '0064899903')
%                 sid = '0058@ISHAR451';
%                 if isfield(secexp, sid, 1)
%                     secexp(:,sid,:) = nanmean(fts2mat(secexp), 2);
%                 end
%             end
%             o.beta = secexp(:,:,fldR2);
%             o.exposure = secexp(:,:,fldFactors);
%             o.specrisk = secexp(:,:,fldSpecificRisk);
%             
%             nFac = length(fldFactors);
%             T = length(o.dates);
%             o.faccov = xts(o.dates, zeros(T, nFac, nFac), fldFactors, fldFactors);
%             for t = 1:T
%                 o.faccov(t,:,:) = eye(nFac);
%             end
%         end
        
        function o = load(o)
        % faccov, exposure, specrisk, beta
            expval = [];
            expdate = [];
            expsecid = {};
            expfld = {};
        
            facflds = strtrim(mat2cell(num2str((1:20)', 'Factor_%d'), ones(20,1)));
            nFac = length(facflds);
            flds = [facflds; 'SpecificRisk'; 'Beta'];
            nFld = length(flds);
            
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                aggid = sprintf(',%s',o.aggid{:});
                EMExp = DB('QuantTrading').runSql('axioma.GetEMRiskExp_Full_New', tstr, aggid(2:end),o.isLive);
                nSid = length(EMExp.SecId);
                expsecid = [expsecid; repmat(EMExp.SecId, nFld, 1)];
                expdate = [expdate; repmat(o.dates(t), nFld*nSid, 1)];
                for i = 1:nFld
                    expval = [expval; EMExp.(flds{i})];
                    expfld = [expfld; repmat(flds(i), nSid, 1)];
                end
            end

            o.exposure = mat2xts(expdate, expval, expsecid, expfld);
            o.specrisk = o.exposure(:,:,'SpecificRisk').*sqrt(52);
            o.beta = o.exposure(:,:,'Beta');
            o.exposure(:,:,{'SpecificRisk', 'Beta'}) = [];
            o.faccov = xts(o.dates, zeros(length(o.dates), nFac, nFac),  facflds, facflds);
            for t = 1:length(o.dates)
                o.faccov(t,:,:) = eye(20)*52;
            end
        end
    end
end

function ret = stackStruct(oldst, newst, date)
    if isempty(oldst)
        ret.val = [];
        ret.fname = {};
        ret.secid = {};
        ret.date = [];
    else
        ret = oldst;
    end
    
    flds = fieldnames(newst);
    N = length(newst.(flds{2}));  % secid
    for i = 2:length(flds)
        ret.val   = [ret.val; newst.(flds{i})]; %#ok<*AGROW>
        ret.fname = [ret.fname; repmat(flds(i), N, 1)];
        ret.secid = [ret.secid; newst.(flds{1})];
        ret.date  = [ret.date; repmat(date, N, 1)];
    end
end
