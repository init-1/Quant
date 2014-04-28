classdef RiskUBS < RiskModel
    methods
        function o = RiskUBS(id, varargin)
        % Usage:
        %     o = RiskUBS(id, owner);
        %     o = RiskUBS(id, dates, aggid, isLive);
        % where
        %      id: the identifier of the model
        %   owner: an AXDataSet object
        %   dates: a vector of numerical dates
        %   aggid: universe id
            o = o@RiskModel(id, varargin{:});            
        end
    end
    
    methods(Access = protected)      
        function o = load(o)
        % faccov, exposure, specrisk, beta
            expval = [];
            expdate = [];
            expsecid = {};
            expfld = {};
            covval = [];
            covdate = [];
            covfld1 = {};
            covfld2 = {};
            o.scale = 12;        
            facflds = cellstr(num2str((1:50)', 'F%02d'));
            nFac = length(facflds);
            flds = [facflds; 'SpecificRisk'; 'Beta'];
            nFld = length(flds);
            
            if ~iscell(o.aggid)
                class_aggid = {o.aggid};
            else
                class_aggid = o.aggid;
            end
                
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                aggid = sprintf(',%s',class_aggid{:});
                UBSExp = DB('QuantTrading').runSql('axioma.GetUBSRiskExp', tstr, aggid(2:end),o.owner.isLive);
                UBSCov = DB('QuantTrading').runSql('axioma.GetUBSRiskCov', tstr, aggid(2:end));
                
                for f = UBSCov.Factor'
                    covval = [covval; UBSCov.(f{:})]; %#ok<*AGROW>
                    covfld1 = [covfld1; UBSCov.Factor];
                    covfld2 = [covfld2; repmat(f, nFac, 1)];
                    covdate = [covdate; repmat(o.dates(t), nFac, 1)];
                end
                
                nSid = length(UBSExp.SecId);
                expsecid = [expsecid; repmat(UBSExp.SecId, nFld, 1)];
                expdate = [expdate; repmat(o.dates(t), nFld*nSid, 1)];
                for i = 1:nFld
                    expval = [expval; UBSExp.(flds{i})];
                    expfld = [expfld; repmat(flds(i), nSid, 1)];
                end
            end

            o.faccov = mat2xts(covdate, covval, covfld1, covfld2);
            o.exposure = mat2xts(expdate, expval, expsecid, expfld);
            o.specrisk = o.exposure(:,:,'SpecificRisk').*sqrt(o.scale);
            o.beta = o.exposure(:,:,'Beta');
            o.r2 = [];
            o.exposure(:,:,{'SpecificRisk', 'Beta'}) = [];           
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