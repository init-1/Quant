classdef RiskModel < Model
    properties (SetAccess = protected)
        faccov
        exposure
        specrisk
        beta
        r2
        scale
    end
    
    properties (Dependent)
        facids
    end
    
    methods
        function o = RiskModel(id, varargin)
        % This is abstract class. The subclass should used like this:
        %     o = RiskModel(id, owner);
        %     o = RiskModel(id, dates, aggid, isLive);
        % where
        %      id: the identifier of the model
        %   owner: an AXDataSet object
        %   dates: a vector of numerical dates
        %   aggid: universe id
        
            o = o@Model(id, varargin{:});
            o.type = 'FactorRiskModel';
            if isa(o.owner, 'AXDataSet')
                o.owner([o.id '.BETA']) = o.beta;
            end
        end
        
        function varargout = alignmodel(o,varargin)
            [varargin{:} exp srisk b] = alignfields(varargin{:},o.exposure,o.specrisk,o.beta,1);
            [varargin{:} exp srisk b fcv] = aligndates(varargin{:},exp,srisk,b,o.faccov,varargin{1}.dates);
            exp = backfill(exp,Inf,'row');
            srisk = backfill(srisk,Inf,'row');
            b = backfill(b,Inf,'row');
            fcv = backfill(fcv,Inf,'row');
            o.owner.dates = exp.dates;
            o.faccov = fcv; 
            o.exposure = exp;
            o.specrisk = srisk;
            o.beta = b;
            varargout = [{o}, varargin];
        end
        
        function risk = calcrisk(o,portfolio)
            [o, spf] = o.alignmodel(portfolio);
            expo = o.exposure;
            srisk = o.specrisk;
            fcv = o.faccov;
            risk = nan(length(o.dates),1);
            for t=1:length(o.dates)
                pf = fts2mat(spf(t,:));
                pf(isnan(pf)) = 0;
                exp = squeeze(expo(t,:,:));
                exp(isnan(exp)) = 0;
                spec = fts2mat(srisk(t,:));
                spec(isnan(spec)) = 0;
                smat = zeros(numel(spec),numel(spec));
                smat(logical(eye(numel(spec)))) = spec.*spec;
                riskmat = exp * squeeze(fcv(t,:,:)) * exp' + smat;
                risk(t) = sqrt(pf*riskmat*pf');
            end
        end
        
        function beta = calcbeta(o,portfolio)
            [o, spf] = o.alignmodel(portfolio);
            beta = nan(length(o.dates),1);
            for t=1:length(o.dates)
                pf = fts2mat(spf(t,:));
                pf(isnan(pf)) = 0;
                beta(t) = nansum(pf.*fts2mat(o.beta(t,:)));
            end
        end
            
        function o = addAlphaFactor(o,alpha)
            % This implements Axioma's Alpha Factor Method to the existing
            % risk model in attempt to solve the misalignment issue
            %
            % input: alpha - myfints object representing alpha/portfolio
            
            %% Align data
            alpha = padfield(alpha, fieldnames(o.exposure,1,1), NaN);
            [spf facexp srisk pbeta] = alignfields(alpha,o.exposure,o.specrisk,o.beta,1);
            [spf facexp srisk pbeta covmat] = aligndates(spf,facexp,srisk,pbeta,o.faccov,o.dates);            
           
            %% Update exposure
            expval = nan(length(facexp.dates),length(fieldnames(facexp,1,1)),1+length(fieldnames(facexp,1,2)));
            for t=1:length(o.dates)
                pf = fts2mat(spf(t,:));
                spec = fts2mat(srisk(t,:));
                exp = squeeze(facexp(t,:,:));
                pf(isnan(pf') & (sum(isnan(exp),2) < size(exp,2))) = 0; %Set alpha for stocks that are in risk model but not present in alpha to be 0
                b = regress(pf',exp); %regress alpha against risk model loadings
                alpha_ = pf' - exp*b; %alpha = exp*b + alpha_
                alpha_ = alpha_./sqrt(nansum(alpha_.*alpha_)); %scale by L2 norm
                exp_ = [exp, nanmean(spec).*alpha_]; %scale by cross-sectional stdev of alpha_
                expval(t,:,:) = exp_;
            end

            o.exposure = xts(facexp.dates, expval, fieldnames(facexp,1,1), [fieldnames(facexp,1,2); {'AAF'}]);
            
            %% Update covariance matrix
            numfac = length(fieldnames(covmat,1,1));
            covval = nan(length(covmat.dates),1+numfac,1+numfac);
            for t=1:length(covmat.dates)
                covval(t,:,:) = eye(1+numfac).*o.scale;
                covval(t,1:numfac,1:numfac) = squeeze(covmat(t,:,:));
            end
            o.faccov = xts(covmat.dates, covval, [fieldnames(covmat,1,1); {'AAF'}], [fieldnames(covmat,1,2); {'AAF'}]);      
            
            %% Update specific risk (id aligned)
            o.specrisk = srisk;
            
            %% Update beta
            o.beta = pbeta; %No adjustment to beta as it is negligible
        end
        
        function fids = get.facids(o)
            fids = fieldnames(o.faccov, 1, 1);
        end
        
        function export(o)
            sids = fieldnames(o.specrisk,1);
            idx = {{o.date}, sids};
            com.axiomainc.portfolioprecision.FactorRiskModel(o.ws, o.id, sids, o.facids ...
                , fts2mat(o.specrisk(idx{:})) ...
                , squeeze(o.exposure(idx{:},:))' ...
                , squeeze(o.faccov({o.date},:,:)));
            
            mg = com.axiomainc.portfolioprecision.Metagroup(o.ws, [o.id '.COMMON FACTORS'], [o.id '.COMMON FACTORS'], o.javadate);
            for i=1:length(o.facids)
                g = o.ws.getGroup([o.id '.' o.facids{i}]);
                mg.addGroup(g,1);
            end
        end
    end
end

    