% This function constructs frequently used constraints given different constraint type 

function cons = ConstraintBuilder(type, varargin)
    switch lower(type)
        %% Asset Level Constraints
        case 'longonly'
            cons.type = 'position';
            cons.unit = 'weight';
            bmhd = varargin{1};
            cons.ub = bmhd;
            cons.lb = bmhd;
            cons.ub(:,:) = 1;
            cons.ub(~fts2mat(bmhd > 0)) = 0;
            cons.lb(:,:) = 0;
        case 'activebet'
            cons.type = 'position';
            cons.unit = 'weight';
            bmhd = varargin{1};
            actbet = varargin{2};
            assert(actbet >= 0, 'the parameter actbet has to be >= 0');
            cons.ub = bmhd + actbet;
            cons.lb = bmhd - actbet;
            cons.ub(~fts2mat(bmhd > 0)) = 0;
            cons.lb(~fts2mat(bmhd > 0)) = 0;
        case 'benchmarktail'
            cons.type = 'position';
            cons.unit = 'weight';
            bmhd = varargin{1};
            liquidhd = varargin{2};
            actbet = varargin{3};
            assert(actbet >= 0, 'the illiquid tail active bet has to be >= 0');
            [bmhd, liquidhd] = aligndata(bmhd, liquidhd, 'union');
            cons.ub = bmhd + actbet;
            cons.lb = bmhd - actbet;
            cons.ub(liquidhd > 0) = Inf;
            cons.lb(liquidhd > 0) = -Inf;
        case 'propactbet'
            cons.type = 'position';
            cons.unit = 'weight';
            bmhd = varargin{1};
            proportion = varargin{2};
            actbet = varargin{3};
            assert(actbet >= 0, 'the parameter actbet has to be >= 0');
            proportion = abs(proportion);
            maxprop = nanmax(proportion,2);
            bound = bsxfun(@rdivide, proportion, maxprop)*actbet;
            bound(isinf(fts2mat(bound)) | isnan(fts2mat(bound))) = actbet;
            cons.ub = bmhd + bound;
            cons.lb = bmhd - bound;
            cons.ub(~fts2mat(bmhd > 0)) = 0;
            cons.lb(~fts2mat(bmhd > 0)) = 0;            
        case 'holdingliquidity'
            cons.type = 'actposition'; % liquidity-based-position size are measured in share volume
            cons.unit = 'share';
            adv = varargin{1};
            percentage = varargin{2};
            cons.ub = percentage*adv; 
            cons.lb = percentage*adv; 
        case 'tradingliquidity'
            cons.type = 'trade'; % liquidity-based-trade size are measured in share volume
            cons.unit = 'share';
            adv = varargin{1};
            percentage = varargin{2};
            cons.ub = percentage*adv; % upper bound means max trade size on buy side
            cons.lb = percentage*adv; % lower bound means max trade size on sell side
            
        %% Attribute Level Constraints
        case 'sumtoone'
            bmhd = varargin{:};
            cons.type = '=';
            cons.A = double(fts2mat(bmhd) > 0);
            cons.A = myfints(bmhd.dates, cons.A, fieldnames(bmhd,1));
            cons.b = 1;
        case 'sectorneutral'
            bmhd = varargin{1};
            gics = varargin{2};
            sectorbet = varargin{3};
            if nargin < 4, level = 1; else level = varargin{4}; end
            assert(isaligneddata(bmhd, gics), 'bmhd and gics are not aligned');
            gics = fts2mat(gics);
            scale = 100^(4-level);
            sector = floor(gics/scale);
            unisec = unique(sector);
            unisec(isnan(unisec)) = [];
            cons = cell(1,numel(unisec)*2);
            for i = 1:numel(unisec)
                cons{i}.type = '<=';
                cons{i}.A = double((sector == unisec(i)) & fts2mat(bmhd) > 0);
                cons{i}.A = myfints(bmhd.dates, cons{i}.A, fieldnames(bmhd,1));
                tempbmhd = fts2mat(bmhd);
                tempbmhd(sector ~= unisec(i)) = 0;
                cons{i}.b = nansum(tempbmhd,2) + sectorbet;
            end
            for i = numel(unisec)+1:2*numel(unisec)
                j = i - numel(unisec);
                cons{i}.A = double((sector == unisec(j)) & fts2mat(bmhd) > 0);
                cons{i}.A = myfints(bmhd.dates, cons{i}.A, fieldnames(bmhd,1));
                tempbmhd = fts2mat(bmhd);
                tempbmhd(sector ~= unisec(j)) = 0;
                cons{i}.type = '>=';
                cons{i}.b = nansum(tempbmhd,2) - sectorbet;
            end
        case 'ctryneutral'
            bmhd = varargin{1};
            ctry = varargin{2};
            ctrybet = varargin{3};
            ctry = reshape(ctry, [1, numel(ctry)]); % ensure it is a row vector
            uniqctry = unique(ctry);
            uniqctry(ismember(uniqctry, {'','NULL','NaN'})) = []; % get rid of missing countries
            nctry = numel(uniqctry);
            
            cons = cell(1,nctry*2);
            for i = 1:nctry
                idx = ismember(ctry, uniqctry(i));
                A = double(repmat(idx,[size(bmhd,1),1]) & fts2mat(bmhd) > 0);
                
                cons{i}.type = '<=';
                cons{i}.A = myfints(bmhd.dates, A, fieldnames(bmhd,1));
                cons{i}.b = nansum(bmhd(:,idx),2) + ctrybet;        
                
                cons{i+nctry}.type = '>=';                
                cons{i+nctry}.A = cons{i}.A;
                cons{i+nctry}.b = nansum(bmhd(:,idx),2) - ctrybet;                
                
                cons{i}.A(isnan(fts2mat(cons{i+nctry}.A))) = 0;
                cons{i+nctry}.A(isnan(fts2mat(cons{i+nctry}.A))) = 0;
            end
    end
    if ~iscell(cons)
        cons = {cons};
    end
        
return