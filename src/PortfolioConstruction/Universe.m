classdef Universe < Exportable
    properties (SetAccess = private)
        names
        map     % a myfints with logical values
    end
    
    properties (Access = private)
        originalMap  % just a copy of initial map
    end
    
    methods
        function o = Universe(isLive, dates, aggid)
            o = o@Exportable('Universe', 'MasterSet');
            o = o.load(isLive, dates, aggid);
            o.originalMap = o.map;
        end
        
        function varargout = size(o, varargin)
            varargout = cell(1, min(nargout,1));
           [varargout{:}] = size(o.map, varargin{:});
        end
        
        function sids = getUniverse(o, dates)
            if nargin < 2, dates = o.map.dates; end
            if isnumeric(dates), dates = num2cell(dates); end
            sids = fieldnames(o.map, 1);
            sids = sids(any(fts2mat(o.map(dates,:)),1));
        end
        
        %%%% Still need a applyUniverse() for user's own purpose
        function fts = applyUniverse(o, fts)
            fts = aligndates(fts, o.map.dates);
            fts = padfield(fts, fieldnames(o.map,1), NaN);
            fts(o.map == false) = NaN;
        end

        function o = trimUniverse(o, fts)
        % NOTE that values of fts must be logical
            fts = aligndates(fts, o.map.dates);
            o.map = o.originalMap & fts;            
        end
        
        function export(o)
            idx = fts2mat(o.map({o.date},:));
            sids = fieldnames(o.map, 1);
            sids = sids(idx);
            nms = o.names(idx);
            for i = 1:size(sids)
                com.axiomainc.portfolioprecision.SimpleAsset(o.ws, sids{i}, nms{i});
            end
        end  
    end
    
    methods (Access = private)
        function o = load(o, isLive, dates, aggid)
            idlist = sprintf(',%s', aggid{:}); % !!!it can be multiple aggids though we currently stick to one aggid
            T = length(dates);
            secids = cell(T,1);
            for t = 1:T
                data = DB('QuantTrading').runSql('axioma.GetUniverse', ...
                       idlist(2:end), datestr(dates(t),'yyyy-mm-dd'), isLive);
                FTSASSERT(sum(cellfun(@(c) any(isnan(c)),data.SecId))==0,'Universe contains null SecId.');
                secids{t} = data.SecId';
            end
            
            sid = unique([secids{:}]);
            map_ = false(T,length(sid));
            for t = 1:T
                map_(t,:) = ismember(sid, secids{t});
            end
            
            o.map = myfints(dates, map_, sid);
            
            % Load name
            idlist = sprintf(',''%s''', sid{:});
            data = DB('QuantStaging').runSql(['select id, name from dbo.SecMstr where id in (' idlist(2:end) ')']);
            [tf, posn] = ismember(sid, data.id);
            o.names = data.name(posn(tf));
        end
    end
end
