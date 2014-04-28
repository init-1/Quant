classdef RiskBarra < RiskModel
    methods
        function o = RiskBarra(id, varargin)
        % Usage:
        %     o = RiskBarra(id, owner);
        %     o = RiskBarra(id, dates, aggid, isLive);
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
            o.scale = 1;
            DB('QuantTrading');
            if isa(o.owner,'AXDataSet')
                sids = o.owner.getUniverse;
                seclist = sprintf(',%s', sids{:}); %%% note do not use o.secids since it is for one day (o.date)
            else
                sids = LoadIndexHoldingTS(o.owner.aggid,datestr(min(o.dates),'yyyy-mm-dd'),datestr(max(o.dates),'yyyy-mm-dd'),o.owner.isLive);
                seclist = sprintf(',%s', sids{:});
            end
            expval = [];
            covval = [];
            covdate = [];
            expdate = [];
            expsecid = {};
            expfld = {};
            covfld1 = {};
            covfld2 = {};
            
            for t = 1:length(o.dates)
                tstr = datestr(o.dates(t), 'yyyy-mm-dd');
                BarraCov = DB.runSql(['DataInterfaceserver.DataQA.api.usp_RiskModel ''D001500094'','''',''' tstr ''',''' tstr '''']);
                BarraExp = DB.runSql('axioma.GetBarraRiskExp_ML',seclist(2:end), tstr);
                nCov = length(BarraCov.Factor);
                nExp = length(BarraExp.SecId);
                
                for f = BarraCov.Factor'
                    covval = [covval; BarraCov.(f{:})]; %#ok<*AGROW>
                    covfld1 = [covfld1; BarraCov.Factor];
                    covfld2 = [covfld2; repmat(f, nCov, 1)];
                    covdate = [covdate; repmat(o.dates(t), nCov, 1)];
                    
                    expval = [expval; BarraExp.(f{:})];
                    expsecid = [expsecid; BarraExp.SecId];
                    expfld = [expfld; repmat(f, nExp, 1)];
                    expdate = [expdate; repmat(o.dates(t), nExp, 1)];
                end
                
                expval = [expval; BarraExp.specificrisk];
                expsecid = [expsecid; BarraExp.SecId];
                expfld = [expfld; repmat({'specificrisk'}, nExp, 1)];
                expdate = [expdate; repmat(o.dates(t), nExp, 1)];
                
                expval = [expval; BarraExp.Beta];
                expsecid = [expsecid; BarraExp.SecId];
                expfld = [expfld; repmat({'Beta'}, nExp, 1)];
                expdate = [expdate; repmat(o.dates(t), nExp, 1)];
            end
            
            o.faccov = mat2xts(covdate, covval, covfld1, covfld2);
            o.exposure = mat2xts(expdate, expval, expsecid, expfld);
            o.faccov(isnan(o.faccov)) = 0;
            o.exposure(isnan(o.exposure)) = 0;
            o.specrisk = o.exposure(:,:,'specificrisk');
            o.beta = o.exposure(:,:,'Beta');
            o.exposure(:,:,{'specificrisk', 'Beta'}) = [];
        end
    end
end

