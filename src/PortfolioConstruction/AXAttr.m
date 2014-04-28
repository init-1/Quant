classdef AXAttr < Exportable & myfints
    properties (Constant, GetAccess = private)
        % Difference between MEGAGROUP and COLLECTION:
        %   MEGAGROUP first creates groups from asset-level myfints then creates the megagroup;
        %   COLLECTION simply creates the megagroup and add already-existing groups to it. 
        %   It's based group-level myfints, values of which are weights of corresponding group in the megagroup
        TYPES = {'ACCOUNT', 'GROUP', 'BENCHMARK', 'TEXTGROUP', 'ASSETMAP', 'METAGROUP', 'COLLECTION', 'SET'};
    end
    
    methods
        function o = AXAttr(id, fts, type)
            o = o@Exportable(id, type);
            o = o@myfints;
            FTSASSERT(ismember(type,o.TYPES), ['type should be one of', sprintf(' %s', o.TYPES{:})]);
            FTSASSERT(isa(fts, 'xts'), 'First arg expected to be a xts object');
            o = copy(o, fts);
        end
        
        function display(o)
            disp([inputname(1) ' = ']);
            disp(['      id: ' o.id]);
            disp(['    type: ' o.type]);
            display@myfints(o);
        end
        
        function ret = getfield(o, field, varargin)
        % Note that we do not provide setfield purposely since we want user set id and type only by constructor
            if ismember(field, {'id', 'type'})
                ret = o.(field);
            else
                ret = getfield@myfints(o, field, varargin{:});
            end
        end

        function st = getSelectionTypeLocally(o, subid)
            switch o.type
                case 'METAGROUP'
                    if isempty(subid)
                        st = AXSelection.METAGROUP;
                    else
                        uids = unique(fts2mat(o));
                        if isnumeric(uids)
                            uids(isnan(uids)) = [];
                        end
                        uids = metagroupsubid(uids);
                        if ismember(subid, uids)
                            st = AXSelection.GROUP;
                        else
                            st = AXSelection.UNKNOWN;
                        end
                    end
                case 'COLLECTION'
                    FTSASSERT(isempty(subid));
                    st = AXSelection.METAGROUP;
                case 'SET'
                    st = AXSelection.SET;
                otherwise
                    st = AXSelection.GROUP;
            end
        end
        
        function ids = getIds(o, dates)
            if nargin < 2, dates = o.dates; end
            
            values = fts2mat(aligndates(o, dates, 'CalcMethod', 'exact'));
            if iscell(values)   % unit should be Unit.TEXT
                idx = cellfun(@(x)any(isnan(x)), values);
                values(idx) = {''};
            end
            
            switch o.type
                case 'METAGROUP'
                    uids = unique(values);
                    if isnumeric(uids)
                        uids(isnan(uids)) = [];
                    elseif iscell(uids)
                        uids(cellfun(@isempty,uids)) = [];
                    end
                    ids = metagroupsubid(uids);
                case 'SET'
                    ids = fieldnames(o, 1);
                    ids = ids(any(values,1));
                otherwise
                    ids = {};
            end
            
            if ~isempty(ids)
                ids = strcat(o.id, '.', ids);
            end
            ids = [o.id; ids(:)];
        end

        function fts = getExport(o)
            if isempty(o)
                fts = o;
                return;
            end
            
            idx = find(o.dates <= o.date, 1, 'last');
            s.type = '()'; s.subs = {idx,':'};
            values = fts2mat(subsref(o,s));
            if iscell(values)   % unit should be Unit.TEXT
                rmidx = cellfun(@isempty, values);
            else
                rmidx = isnan(values);
            end
            sids = fieldnames(o,1);
            sids(rmidx) = [];                  % exclude non-existing things
            values(rmidx) = [];
            if ~ismember(upper(o.type), {'SET', 'COLLECTION'})
                [sids,idx] = intersect(sids, [o.secids; 'CASH']); % exclude not-in-universe things. At least not right for ASSETSET
                values = values(idx);
            end
            
            if isempty(values)
                fts = myfints;
            else
                fts = myfints(o.date, values, sids);
            end
        end
    
        function export(o)
            fts = getExport(o);
            sids = upper(fieldnames(fts,1));
            values = fts2mat(fts);
            
            if isempty(sids)
                com.axiomainc.portfolioprecision.SimpleGroup(o.ws, o.id, o.desc, ...
                     com.axiomainc.portfolioprecision.Unit.valueOf('NUMBER'));
                return;
            end
            
            switch o.type
              case 'ACCOUNT'
                 com.axiomainc.portfolioprecision.Account(o.ws, o.id, sids, values);
              case 'ASSETMAP'
                 am = com.axiomainc.portfolioprecision.AssetMap(o.ws, o.id, o.desc, true, o.javadate);
                 for i = 1:length(sids)
                     if ~ischar(values{i}), values{i} = sids{i}; end
                     am.addAssetMapping(o.ws.getAsset(sids{i}), values{i});
                 end                  
              case 'TEXTGROUP'
                 tg = com.axiomainc.portfolioprecision.TextGroup(o.ws, o.id, o.desc, ...
                      com.axiomainc.portfolioprecision.Unit.valueOf(o.Unit));
                 for i = 1:length(sids)
                     tg.setComposition(o.ws.getAsset(sids{i}), values{i});
                 end
              case 'GROUP'
                 com.axiomainc.portfolioprecision.SimpleGroup(o.ws, o.id, ...
                     com.axiomainc.portfolioprecision.Unit.valueOf(char(o.unit)), ...
                     sids, values);
              case 'BENCHMARK'
                 com.axiomainc.portfolioprecision.Benchmark(o.ws, o.id, ...
                     com.axiomainc.portfolioprecision.Unit.valueOf(char(o.unit)), ...
                     sids, values);
              case 'METAGROUP'
                 mg = com.axiomainc.portfolioprecision.Metagroup(o.ws, o.id, o.desc, o.javadate);
                 if iscell(values)
                    idx = cellfun(@(c) any(isnan(c)),values);
                    if nansum(idx) > 0
                        values{idx} = 'UNIDENTIFIED';
                    end
                 end
                 [uvals,~,n] = unique(values);
                 uvals = metagroupsubid(uvals);
                 for i = 1:length(uvals)
                     sids_ = sids(n==i);
                     sg = com.axiomainc.portfolioprecision.SimpleGroup(o.ws, [o.id '.' uvals{i}], ...
                          com.axiomainc.portfolioprecision.Unit.NUMBER, sids_, ones(size(sids_)));
                     mg.addGroup(sg, 1);
                 end
              case 'COLLECTION'
                 mg = com.axiomainc.portfolioprecision.Metagroup(o.ws, o.id, o.desc, o.javadate);
                 loc = find(~isnan(values) & values ~= 0);
                 for i = loc(:)'
                     mg.addGroup(o.ws.getGroup(sids{i}), values(i));
                 end
              case 'SET'
                  if isempty(o.ws.getAssetSet(o.id))
                      set = com.axiomainc.portfolioprecision.AssetSet(o.ws, o.id, o.desc, o.javadate);
                      for i = 1:length(sids)
                        switch o.getSelectionType(sids{i});
                          case AXSelection.ASSET
                              if values(i)
                                  set.includeAsset(o.ws.getAsset(sids{i}));
                              else
                                  set.excludeAsset(o.ws.getAsset(sids{i}));
                              end
                          case AXSelection.GROUP
                              if values(i)
                                  set.includeGroup(o.ws.getGroup(sids{i}));
                              else
                                  set.excludeGroup(o.ws.getGroup(sids{i}));
                              end
                          case AXSelection.METAGROUP
                              if values(i)
                                  set.includeMetagroup(o.ws.getMetagroup(sids{i}));
                              else
                                  set.excludeMetagroup(o.ws.getMetagroup(sids{i}));
                              end
                          case AXSelection.SET
                              a = o.getData(sids{i});
                              if ~isempty(a)
                                export(a);
                              end
                              if values(i)
                                  set.includeAssetSet(o.ws.getAssetSet(sids{i}));
                              else
                                  set.excludeAssetSet(o.ws.getAssetSet(sids{i}));
                              end
                          otherwise
                              FTSASSERT(false, ['Invalid selection type for ' sids{i}]);
                        end
                      end
                  end % if isempty()
              otherwise
                 FTSASSERT(false, ['Unrecognized exportable type: ' o.type]);
           end
        end
    end
end

function vals = metagroupsubid(vals)
    if isnumeric(vals)
        if isrow(vals), vals = vals'; end
        vals = num2str(vals);
        vals = mat2cell(vals, ones(size(vals,1),1));
        vals = strtrim(vals);
    else
        FTSASSERT(iscell(vals));
        vals = regexprep(vals, ' ', '_');
    end
    vals = upper(vals);
end