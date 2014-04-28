classdef xts
    properties (SetAccess = protected)
        freq = 0;
        desc = '';
        unit = Unit.NUMBER;
        dates       % time always be the first dimension and should be unique and ordered
        fields      % a cell of cell vector, each element cell is a cell-string vector corresponding to a dimension
        data        % n-dimensional array where n = 1(time dimension) + length(dimlabels)
    end
    
    properties (Dependent, SetAccess = protected)
        ndims
    end
    
    methods (Access = protected)
        function subs = parseIndex(o, s)
            subs = [];
            if strcmp(s(1).type,'()')
                % check s(1). Acutally only s(1) exists (no element s(2)...)
                subs = s(1).subs;
                dim = length(subs);
                if dim == 1  % 1-D indexing
                    subs = subs{:};
                    % 1-D index could be a 2-D matrix or xts obj
                    if isa(subs, 'xts') && subs.ndims == o.ndims
                        FTSASSERT(isaligneddata(o,subs)...
                            , 'indexing object is not aligned to indexed object');
                        subs = subs.data;
                    elseif isvector(subs) && ~islogical(subs)  % include numeric and string
                        if iscell(subs) || ischar(subs)
                            subs = processDateRange(o, subs); % now subs should be index to xts.dates
                        else  % normal numeric index, sorting to make sure date-ordered
                            subs = sort(subs);
                        end
                        subs = [subs, repmat({':'}, 1, o.ndims-1)];
                        return;  % with xts not touched
                    end
                    
                    FTSASSERT(isnumeric(subs) || islogical(subs), 'invalid index');
                    FTSASSERT(isequal(size(subs),size(o)), 'dimension mismatch between indexing and indexed objs');
                    subs = {subs};
                elseif dim == o.ndims
                    if iscell(subs{1}) || (ischar(subs{1}) && ~strcmp(subs{1},':'))
                        subs{1} = processDateRange(o, subs{1}); % now subs should be index to xts.dates
                    elseif ~islogical(subs{1})
                        subs{1} = sort(subs{1});  % to make sure dates sorted
                    end
                    
                    for n = 2:o.ndims
                        if ischar(subs{n}) && ~strcmp(subs{n},':'), subs{n} = subs(n); end
                        if iscell(subs{n})  % cell string
                            [~, subs{n}] = ismember(subs{n}, o.fields{n-1}); % fields labels dimensions from 2
                            FTSASSERT(all(subs{n}), 'Fields not exist in xts');
                        end
                    end
                else
                    FTSASSERT(false, 'invalid index: dimension mismatch between index and indexed objs');
                end
            end
        end % OF PARSEiNDEX
        
        function idx = processDateRange(o, date_range)
            if ischar(date_range)
                date_range = {date_range};
            end
            
            FTSASSERT(iscell(date_range), 'date range shoud be a cell vector of string or char string');
            
            idx = false(size(o.dates));
            
            for i = 1:length(date_range)
                dts = date_range{i};
                if ischar(dts)
                    [~,~,~,~,~,~,parts] = regexp(dts, '::', 'match');
                    dts = datenum(parts);
                    FTSASSERT(length(dts) <= 2, 'invalid date range expression');
                end
                
                n = length(dts);
                if n == 1
                    idx = idx | o.dates == dts(1);
                else
                    idx = idx | (o.dates >= dts(1) & o.dates <= dts(n));
                end
            end
        end
        
        function o = checkDates(o)
            % Conformability checking and fixing
            % check time dimension
            FTSASSERT(isvector(o.dates) || isempty(o.dates),  'dates should be a vector');
            FTSASSERT(numel(o.dates) == size(o.data,1), 'date and data dimension mismatched');
            
            % remove duplicated dates and assoicated data
            o.dates = fix(o.dates);  % remove hour, minutes, second parts in dates
            [o.dates, m, n] = unique(o.dates, 'first');
            if length(m) ~= length(n)
                warning('xfs:chk:DuplicatedDates', 'duplicated dates detected (data first occurance used)');
            end
            if isrow(o.dates), o.dates = o.dates'; end  % dates always column vector
            fldsubs = repmat({':'}, 1, o.ndims-1);
            o.data = o.data(m, fldsubs{:});
        end
        
        function o = checkFields(o)
            % check field dimensions
            % Notice that some trailing dimensions may be singleton. In that case, we
            % will remove those trailing dimensions.
            if isempty(o), return; end
            
            nFieldDims = o.ndims - 1;
            dims = size(o.data);
            %             while length(o.fields) > 1 && length(o.fields{end}) == 1, o.fields(end) = []; end
            FTSASSERT(nFieldDims <= length(o.fields), 'Number of field dimensions mismatched that of data');
            o.fields = o.fields(1:nFieldDims);  % remove redauntant fields
            
            for i = 1:nFieldDims
                fld_i = o.fields{i};  % fieldnames for (i+1)-th dimension (1st for time)
                if isempty(fld_i), fld_i = 'series'; end
                if ischar(fld_i),  fld_i = {fld_i}; end
                FTSASSERT(isvector(fld_i), 'fieldname(s) provied must be a vector');
                
                dim_i = dims(i+1); % still, note 1st dimension for time
                if numel(fld_i) == 1 && dim_i > 1
                    fld_i = strtrim(mat2cell(num2str((1:dim_i)',[fld_i{1} '%d']), ones(dim_i,1)));
                end
                
                FTSASSERT(numel(fld_i)==dim_i, ['Dimension (' num2str(i+1) ') mismatched between fieldnames and data']);
                FTSASSERT(length(unique(fld_i))==length(fld_i), 'Duplicated fieldnames detected');
                if iscolumn(fld_i), fld_i = fld_i'; end  % fieldnames for each dimension always row vector
                o.fields{i} = fld_i;
            end
        end
        
        function o = xtsreturn(o, newdata, fieldname, dates)
            % This function will be used by uniftsfun, biftsfun, aligndates, alginfields.
            if nargin > 2 && islogical(fieldname) && ~fieldname
                o = newdata;
                return;
            end
            
            o.data = newdata;
            
            if nargin < 4 || isempty(dates)   % if not provide dates. This is very useful in subsasgn() in A(:,'s2')=[]
                % Check size of calculated result.
                nNewDates = size(newdata,1);
                if nNewDates == 1 % If result has just one row, the returned fints has last date labeled
                    o.dates = o.dates(end);
                elseif nNewDates ~= length(o.dates) % else dimension matched, directly return matrix data
                    o = newdata;
                    return;
                end  % else stick to the o.dates
            else
                o.dates = dates;
                o = checkDates(o);
            end
            
            if nargin >= 3 && ~isempty(fieldname) % if provide fieldname; otherwise we stick to o.fields
                if ischar(fieldname)
                    fieldname = {{fieldname}};  % now filedname like {{'aa'}}
                else
                    FTSASSERT(iscell(fieldname), 'fieldname  must be a char string, cell of strings, or cell of cell of strings');
                    tf = ~cellfun(@iscell, fieldname); % check if there's cell elements in fieldname
                    if all(tf)  % if all are not cell, then user provided a cell of strings
                        fieldname = {fieldname}; % now fieldname like {{'aa', 'bbb'}}
                    else  % then fieldname like {{'aa','bbb'},'cc', '', {'dd','efg'}, 'ibm'}
                        % convert those in fieldname not cell to cell
                        loc = find(tf);
                        for i = 1:length(loc)
                            idx = loc(i);
                            if isempty(fieldname{idx}) && idx <= length(o.fields) % provided is null and old exists
                                fieldname{idx} = o.fields{idx}; % use old field names
                            else
                                fieldname{idx} = fieldname(idx); % user provide char-type fieldnames,convert to cell
                            end
                        end
                    end
                end
                o.fields = fieldname;
            end
            
            o = downcast(checkFields(o));
        end
    end  % methods
    
    methods
        %% Constructor
        function o = xts(varargin)
            % Syntax: Constructor syntax is the same as that of fints class
            %	xts = myfints()
            %	xts = myfints(dates, data)
            %	xts = myfints(dates, data, fieldnames1, ..., fieldnamesN)
            %	xts = myfints(dates, data, fieldnames1, ..., fieldnamesN, freq)
            %	xts = myfints(dates, data, fieldnames1, ..., fieldnamesN, freq, desc)
            %	xts = myfints(dates, data, fieldnames1, ..., fieldnamesN, freq, desc, unit)
            if nargin == 0
                o.dates = [];
                o.data = [];
                o.fields = {};
                return;
            end
            
            FTSASSERT(nargin > 1, 'Too few arguments in constructing xts');
            o.dates = datenum(varargin{1});
            o.data  = varargin{2};
            nFieldDims = ndims(o.data)-1;  % get number of dimension of data, excl. time
            
            maxNumArgs = 5 + nFieldDims;  % dates, data, datanames1, datanames2, ..., datanamesN, freq, desc, unit
            FTSASSERT(nargin <= maxNumArgs, 'Too many arguments in construcing xts');
            o.fields = cell(nFieldDims,1); % each element is a cell vector of strings which are field names of one dimension
            
            if nargin < maxNumArgs
                o.unit = Unit.NUMBER;
            else
                o.unit = varargin{maxNumArgs};
                FTSASSERT(isa(o.unit, 'Unit'), 'Invalid unit provided');
            end
            
            if nargin < maxNumArgs - 1
                o.desc = '';
            else
                o.desc = varargin{maxNumArgs-1};
                FTSASSERT(isa(o.desc, 'char') && isrow(o.desc), 'Invalid desc provided');
            end
            
            if nargin < maxNumArgs - 2
                o.freq = 0;
            else
                o.freq = Freq.freqnum(varargin{maxNumArgs-2});
            end
            
            if nargin > 2
                o.fields(1:maxNumArgs-5) = varargin(3:maxNumArgs-3); % move part of varargin which are field names to fields
            end
            
            o = checkFields(checkDates(o));  % Conformability checking and fixing
        end
        
        function n = get.ndims(o)
            n = ndims(o.data);
        end
        
        function o = copy(o, otherxts)
            o.freq = otherxts.freq;
            o.desc = otherxts.desc;
            o.data = otherxts.data;
            o.unit = otherxts.unit;
            o.dates  = otherxts.dates;
            o.fields = otherxts.fields;
        end
        
        function o = downcast(o)
            if o.ndims == 2 && ~isa(o, 'myfints')
                o = copy(myfints, o);
            end
        end
        
        function o = upcast(o)
            if o.ndims > 2 && isa(o, 'myfints')
                o = copy(xts, o);
            end
        end
        
        function o = squeeze(o)
            if o.ndims == 2, return; end  % 2-D unaffected
            singletonDims = size(o.data) == 1;
            o.data = squeeze(o.data);  % o.ndims may have changed since here
            if singletonDims(1)
                if sum(singletonDims) == 1  % if only time dimension is singleton
                    o = o.data;  % directly return data
                    return;
                end  % there's other dimensions except time are also singleton, then keep time dimension
                o.data = reshape(o.data, [1 size(o.data)]);
            end
            o.fields(singletonDims(2:end)) = [];
            o = downcast(o);
        end
        
        %% Indexing Operations
        function o = subsasgn(o, s, b)
            if strcmp(s(1).type, '.')
                fld = s(1).subs;
                if length(s) > 1
                    FTSASSERT(length(s) == 2 && strcmp(s(2).type, '()'), 'Invalid indexing');
                    dates_ = s(2).subs{:};
                else
                    dates_ = ':';
                end
                o = setfield(o, fld, dates_, b);
                return;
            end
            
            FTSASSERT(length(s)==1, 'This type of index not supported currently');
            subs = o.parseIndex(s);
            
            % check b
            if isa(b, 'xts')
                FTSASSERT(isaligneddata(subsref(o,s), b), 'RHS not aligned to LHS');
                b = b.data;
            end
            
            if isempty(b)  % in this case, some part of xts may be removed
                if isempty(o.data(subs{:})), return; end
                
                FTSASSERT(length(subs) == o.ndims, 'Subscripted assignment dimension mismatch');
                
                % Rmove part of matrix. Let Matlab detect if there's errors in subs
                o.data(subs{:}) = [];  % CANNOT be o.data(subs{:})=b due to matlab's bug
                o.freq = 0;
                
                % Process fields, incl. dates (1st dimension)
                if isempty(o.data)
                    o.dates = [];
                    o.fields = {};
                else
                    %%% Note that only one dimension index can be ':'
                    if ~ischar(subs{1}) || ~strcmp(subs{1}, ':')
                        o.dates(subs{1}) = [];
                    else
                        for i = 2:length(subs)
                            if ~ischar(subs{i}) || ~strcmp(subs{i},':')
                                o.fields{i-1}(subs{i}) = [];
                                break;
                            end
                        end
                        o.fields = o.fields(1:o.ndims-1); % readjust dimension
                        o = downcast(o);
                    end
                end
            else
                sz = size(o.data);
                o.data(subs{:}) = b;  % in this case, just modifying some data
                FTSASSERT(isequal(sz, size(o.data)), 'Index exceeds xts dimensions.');
            end
        end
        
        function res = subsref(o, s)
            if strcmp(s(1).type, '.')
                res = getfield(o, s(1).subs); %#ok<GFLD>
                if length(s) > 1
                    res = subsref(res, s(2:end));
                end
                return;
            end
            
            s1 = s(1);
            subs = o.parseIndex(s1);
            
            % New style index
            o.data = o.data(subs{:});   % return a matrix in this case, trailing dimesion of 1s will disappear
            if isvector(o.data) && length(subs) == 1 %% should subs be a logical???
                res = o.data;
            else
                if length(subs) > 1  % should be o.ndims
                    o.dates = o.dates(subs{1});
                    o.fields = o.fields(1:o.ndims-1); % readjust dimension
                    for i = 1:o.ndims-1
                        o.fields{i} = o.fields{i}(1,subs{i+1}); % 2-D indexing to make sure o.fields{i} keep it shape (i.e., row vector)
                    end
                    o.freq = 0;
                end   % otherwise data must be the same size as the original
                res = downcast(o);
            end
            
            if length(s) > 1
                res = subsref(res, s(2:end));
            end
        end
        
        function endidx = end(o, K, ~)
            endidx = size(o,K);
        end
        
        %% Aligning Functions
        function varargout = aligndata(varargin)
            % Syntax:
            %   [ofts1, ofts2, ...] = aligndata(ifts1, ifts2, ...)
            %   [ofts1, ofts2, ...] = aligndata(ifts1, ifts2, ..., mode)
            %   [ofts1, ofts2, ...] = aligndata(ifts1, ifts2, ..., aligningdates)
            %   [ofts1, ofts2, ...] = aligndata(ifts1, ifts2, ..., mode, aligningdates)
            %   [ofts1, ofts2, ...] = aligndata(ifts1, ifts2, ..., aligningdates, mode)
            %   [ofts1, ofts2, ...] = aligndata(..., 'CalcMethod', calcMethod)
            %
            % where
            %   ifts1, ifts2,... : myfints objects to be aligned. Multiple such objects
            %                      are allowed.
            %   ofts1, ofts2,... : returned myfints objects that have been aligned.
            %                      Each one corresponds to the inputted one.
            %   mode             : control how the fields in time series aligned.
            %                      Values can be one of
            %                      'union' : include all (unique) fields occurred in all
            %                                inputted myfints objects. NaNs are filled
            %                                for original nonexistent fields.
            %                  'intersect' : only take the common fields in all
            %                                inputted myfints objects. Fields specific
            %                                to a certain myfints object are removed.
            %                   *  DEFAULT is 'intersect'.
            %   aligningdates    : A vector of dates (numeric vector or cell vector of date
            %                      string) to be aligned OR
            %                      a char vector (string) or scalar number
            %                      indicating aligned frequency
            %                      which can be 'D', 'M', ..., the same as
            %                      convertto() of matlab's fints.
            %                      All the inputted myfints objects will be aligned
            %                      against this date vector or specified frequency.
            %                      Returned objects being aligned
            %                      have the aligningdates or equivelent (to specified
            %                      frequency) as their date field.
            %
            %                    * For returned objects, on a certain date,
            %                      data are the most recent available (known) data
            %                      between the date (inclusive) and its previous date
            %                      (exclusive).
            %
            %                    * If no data in inputted objects available
            %                      in a period (specified or divided by aligneddates)
            %                      NaNs will be filled.
            %
            %                    * If NOT provided, aligned dates will be the common dates
            %                      in all inputted objects.
            %
            if ischar(varargin{end-1}) && strcmpi(varargin{end-1}, 'CalcMethod')
                calcMethod = varargin{end};
                varargin(end-1:end) = [];
            else
                calcMethod = 'Nearest';
            end
            
            date = {};
            mode = {};
            for i = 1:2
                arg = varargin{end};
                if isa(arg, 'xts'), break; end
                if ischar(arg) && ismember(arg, {'union', 'intersect'})
                    mode = {arg};
                else
                    date = {arg};
                end
                varargin(end) = [];
            end
            
            varargout = cell(size(varargin));
            [varargout{:}] = aligndates(varargin{:}, date{:}, 'CalcMethod', calcMethod);
            [varargout{:}] = alignfields(varargout{:}, mode{:});
        end
        
        function varargout = aligndates(varargin)
            % Syntax:
            %   [ofts1, ofts2, ...] = aligndates(ifts1, ifts2, ...)
            %   [ofts1, ofts2, ...] = aligndates(ifts1, ifts2, ..., aligningdates)
            %   [ofts1, ofts2, ...] = aligndates(..., 'CalcMethod', calcMethod)
            % See aligndata
            if ischar(varargin{end-1}) && strcmpi(varargin{end-1}, 'CalcMethod')
                calcMethod = lower(varargin{end});
                varargin(end-1:end) = [];
                FTSASSERT(ismember(calcMethod, {'cumsum', 'exact', 'nearest', 'simavg'}), 'Invalid calcmethod');
            else
                calcMethod = 'nearest';
            end
            
            freq_ = [];
            if isa(varargin{end}, 'xts')
                dates_ = varargin{1}.dates;
                for ixts = varargin(2:end)
                    dates_ = intersect(dates_, ixts{:}.dates);
                end
                T = 0;  % we don't use T in this case, so use it as a flag
            else  % we treat the last argument as a vector of date
                arg = varargin{end};
                varargin(end) = [];  % remove the non-myfints object from argument list
                if ischar(arg) || ...    % something like 'M', 'monthly'
                        isscalar(arg) && isnumeric(arg) && arg < 7 % or like 1,2,...
                    dates_ = varargin{1}.dates;
                    startDate = dates_(1);
                    endDate   = dates_(end);
                    for ixts = varargin(2:end)
                        dates_ = ixts{:}.dates;
                        startDate = min(startDate, dates_(1));
                        endDate   = max(endDate, dates_(end));
                    end
                    % arg in this case actually is freq indicator
                    freq_ = Freq.freqnum(arg);
                    dates_ = Freq.genDateSeries(startDate, endDate, freq_, 'BusDays', 0);
                else
                    dates_ = datenum(arg);  % arg is a vector of doubled dates
                end
                T = length(dates_);
                idx = NaN(T,1);
            end
            
            varargout = cell(size(varargin));
            for i = 1:length(varargin)
                ixts = varargin{i};
                if T == 0  % align among xts objects by intersection of dates
                    idx = ismember(ixts.dates, dates_);
                    ixtsdata = ixts.data;
                else % align to an independent date vector
                    sz = size(ixts.data);
                    if iscell(ixts.data)
                        ixtsdata = [ixts.data; cell([1 sz(2:end)])];
                        fun_isnan = @(x)cellfun(@isempty, x);
                        calcMethod = 'nearest'; % only method allowed for cell-type xts
                    else
                        ixtsdata = [ixts.data; NaN([1 sz(2:end)])];
                        fun_isnan = @isnan;
                    end
                    prevdate = 0;
                    for t = 1:T
                        currdate = dates_(t);
                        loc = find(ixts.dates <= currdate & ixts.dates > prevdate);
                        if isempty(loc) % not found
                            idx(t) = sz(1) + 1;  % point to the NaN entry
                        else
                            last = loc(end);
                            idx(t) = last;
                            switch calcMethod
                                case 'nearest'
                                    for j = 1:length(loc)-1
                                        is_nan = fun_isnan(ixtsdata(last,:));
                                        if any(is_nan)
                                            ixtsdata(last,is_nan) = ixtsdata(last-j,is_nan);
                                        end
                                    end
                                case 'cumsum'
                                    ixtsdata(last,:) = nansum(ixtsdata(loc,:),1);
                                case 'simavg'
                                    ixtsdata(last,:) = nanmean(ixtsdata(loc,:),1);
                                case 'exact'  % nothing to do
                            end
                        end
                        prevdate = currdate;
                    end
                end
                
                fldsubs = repmat({':'}, 1, ixts.ndims-1);
                ixts = xtsreturn(ixts, ixtsdata(idx,fldsubs{:}), '', dates_);
                varargout{i} = ixts.setfield('freq', freq_);
            end
        end
        
        function varargout = alignfields(varargin)
            % Syntax:
            %   [oxts1, oxts2, ...] = aligndata(ixts1, ixts2, ...)
            %   [oxts1, oxts2, ...] = aligndata(ixts1, ixts2, ..., mode)
            %   [oxts1, oxts2, ...] = aligndata(ixts1, ixts2, ..., flddim)
            %   [oxts1, oxts2, ...] = aligndata(ixts1, ixts2, ..., mode, flddim)
            %   [oxts1, oxts2, ...] = aligndata(ixts1, ixts2, ..., flddim, mode)
            % If no flddim provided, it means aligning all field dimensions.
            % See also aligndata
            flddim = 0;
            mode = 'intersect';
            for i = 1:2
                if isnumeric(varargin{end})
                    flddim = varargin{end};
                elseif ischar(varargin{end})
                    mode = lower(varargin{end});
                else
                    FTSASSERT(isa(varargin{end}, 'xts'), 'Unexpected argument');
                    break;
                end
                varargin(end) = [];
            end
            
            nd = cellfun(@(x)x.ndims, varargin);
            FTSASSERT(all(flddim < nd), 'Field dimension specified exceeds number of dimensions of xts objects');
            if flddim == 0  % require aligning all field dimensions
                FTSASSERT(all(nd==nd(1)), 'Since flddim == 0, all xfts objects to be field-aligned must have the same number of dimensions');
                alignedDims = 1:nd(1)-1;  % excluding time dimension
            else
                alignedDims = flddim;
            end
            
            %%%%%varargout = cell(size(varargin));
            for idim = alignedDims
                flds = varargin{1}.fields{idim};
                switch(mode)
                    case 'union'
                        for ixts = varargin(2:end)
                            flds = union(flds, ixts{:}.fields{idim});
                        end
                        flds = unique(flds);
                        for i = 1:length(varargin)
                            varargin{i} = padfield(varargin{i}, flds, NaN, idim);
                        end
                    case 'intersect'
                        for ixts = varargin(2:end)
                            flds = intersect(flds, ixts{:}.fields{idim});
                        end
                        flds = sort(flds);
                        for i = 1:length(varargin)
                            varargin{i} = extfield(varargin{i}, flds, idim);
                        end
                end
            end
            varargout = varargin;
        end
        
        %% Checking if aligned
        function ret = isaligneddata(varargin)
            ret = isaligneddates(varargin{:}) && isalignedfields(varargin{:});
        end
        
        function ret = isaligneddates(varargin)
            FTSASSERT(all(cellfun(@(x)isa(x,'xts'), varargin)), 'All arguments must be type of xts');
            dates_ = varargin{1}.dates;
            for i = 2:length(varargin)
                if ~isequal(dates_, varargin{i}.dates)
                    ret = false;
                    return;
                end
            end
            ret = true;
        end
        
        function ret = isalignedfields(varargin)
            % ret = isalignedfields(xts1,...,xtsn)
            % ret = isalignedfields(xts1,...,xtsn, flddim)
            if ~isa(varargin{end}, 'xts')
                flddim = varargin{end};
                varargin(end) = [];
                eqfun = @(x,y) isequal(x{flddim}, y{flddim});
            else % compare the whole fields (along each dimension)
                eqfun = @isequal;
            end
            
            fields_ = varargin{1}.fields;
            for i = 2:length(varargin)
                if ~eqfun(fields_, varargin{i}.fields)
                    ret = false;
                    return;
                end
            end
            ret = true;
        end
        
        %% Standard operations on myfints
        function display(o)
            try
                fprintf(['\n' inputname(1) ' = \n']);
                
                % Setup description information
                if isempty(o.desc)
                    descdata = '(none)';
                else
                    descdata = o.desc;
                end
                
                if o.freq == 0
                    freqdata = '(none)';
                else
                    freqdata = [Freq.str_long{o.freq} ' (' num2str(o.freq) ')'];
                end
                
                fprintf('    desc:  %s\n    freq:  %s\n    unit:  %s\n', descdata, freqdata, char(o.unit));
                sz = size(o.data);
                fprintf('    size:  %d(dates)', sz(1));
                fprintf(' x %d', sz(2:end));
                fprintf('\n\n');
                
                if isempty(o.data)
                    disp('    empty myfints');
                else
                    if iscell(o.data)
                        fmtdata = o.data;
                    else
                        fmtdata = num2cell(o.data);
                    end
                    
                    cdates = mat2cell(datestr(double(o.dates),'yyyy-mm-dd'),ones(length(o.dates),1));
                    ctitle = ['dates' o.fields{1}];
                    if o.ndims > 2
                        prods = [1 cumprod(sz(o.ndims:-1:3))];
                        idx = zeros(o.ndims-2, prods(end));
                        sz(2) = 1; % make kron properly
                        for n = 3:o.ndims
                            idx(n-2,:) = kron(kron(ones(1,prods(end-n+2)), 1:sz(n)), ones(1,sz(n-1)));
                        end
                        for i = idx
                            ci = num2cell(i);
                            flds = cellfun(@(x,y)x(y), o.fields(2:end), ci);
                            disp([inputname(1) '(:,:' sprintf(',%s', flds{:}) ') = ']);
                            disp([ctitle; cdates fmtdata(:,:,ci{:})]);
                        end
                    else
                        disp([ctitle; cdates fmtdata]);
                    end
                end
            catch %#ok
                error('xts:display:DisplayError', 'Display error.');
            end
        end
        
        function fnames = fieldnames(o, seriesOnlyFlag, flddim)
            if nargin < 3, flddim = 1; end
            if nargin < 2, seriesOnlyFlag = 0; end
            
            if seriesOnlyFlag == 0
                fnames = {'desc'; 'freq'; 'dates'; 'unit'};
            else
                fnames = {};
            end
            if ~isempty(o.fields)
                fnames = [fnames; o.fields{flddim}'];
            end
        end
        
        function ret = getfield(o, field, dates_)
            FTSASSERT(ischar(field), [inputname(2) ' should be a char specifying the name of field to be retrieved']);
            
            if strcmp(field, 'dates')
                if nargin < 3, dates_ = ':'; end
                ret = o.dates(dates_);
            elseif o.isproperty(field)
                ret = o.(field);
            else
                FTSASSERT(0, ['Unrecognized field: ', field]);
            end
        end
        
        function o = setfield(o, field, varargin)
            % o = setfield(o, fld, value)
            % o = setfield(o, fld, dates, value)
            FTSASSERT(ischar(field), [inputname(2) ' must be a char string']);
            if nargin == 4
                dates_ = varargin{1};
                v = varargin{2};
            else
                FTSASSERT(nargin == 3, 'Unexpected number of arguments');
                dates_ = ':';
                v = varargin{1};
            end
            
            if strcmp(field, 'dates')
                v = datenum(v);
                FTSASSERT(strcmp(dates_, ':') && length(v) == length(o.dates) || length(v) == length(dates_), 'Dimension mismatched in setting dates');
                o.dates(dates_) = v;
                FTSASSERT(issorted(o), 'dates unsorted');
                return;
            end
            
            if strcmp(field, 'freq')
                o.freq = Freq.freqnum(v);
            elseif strcmp(field, 'desc')
                FTSASSERT(ischar(v) && isrow(v), 'desc must be a char-type string');
                o.desc = v;
            elseif strcmp(field, 'unit')
                FTSASSERT(isa(v,'Unit'), 'unit must be the enumeration type of Unit');
                o.unit = v;
            else
                FTSASSERT(0, ['Unrecognized field: ', field]);
            end
        end
        
        function o = extfield(o, fldnames, flddim)
            if nargin < 3, flddim = 1; end
            s.type = '()';
            s.subs = repmat({':'}, 1, o.ndims);
            s.subs{flddim+1} = fldnames;
            o = subsref(o, s);   %%  fts = fts(:, fldnames);
        end
        
        function o = rmfield(o, rmflds, flddim)
            if nargin < 3, flddim = 1; end
            flds = o.fields{flddim};
            tf = ismember(flds, rmflds);
            o = extfield(o, flds(~tf), flddim);
        end
        
        function o = padfield(o, fields, padStuff, flddim)
            % Pad fts with fields not existing in it with padStuff (default NaN).
            if nargin < 4, flddim = 1; end
            if nargin < 3, padStuff = NaN; end
            
            if ischar(fields), fields = {fields}; end
            if iscolumn(fields), fields = fields'; end
            N = length(fields);
            
            sz = size(o.data);
            sz(flddim+1) = N;
            oldData = o.data;
            if iscell(o.data)
                o.data = cell(sz);
                o.data(:,:) = {padStuff};
            else
                o.data = ones(sz) .* padStuff;
            end
            
            [tf, loc] = ismember(o.fields{flddim}, fields);
            lsubs = repmat({':'}, 1, o.ndims);
            rsubs = lsubs;
            lsubs{flddim+1} = tf;
            rsubs{flddim+1} = loc(tf);
            o.data(rsubs{:}) = oldData(lsubs{:});
            o.fields{flddim} = fields;
        end
        
        function o = chfield(o, oldname, newname, flddim)
            if nargin < 4, flddim = 1; end;
            if ischar(oldname), oldname = {oldname}; end
            if ischar(newname), newname = {newname}; end
            FTSASSERT(length(oldname) == length(newname), ['Dimension mismatch between ' inputname(2) ' and ' inputname(3)]);
            
            [tf, loc] = ismember(oldname, o.fields{flddim});
            if ~all(tf)
                warning('xts:chfield', 'some old filed names specified do not exist');
            end
            o.fields{flddim}(loc(tf)) = newname(tf);
        end
        
        function tf = isfield(o, fldname, flddim)
            if nargin < 3, flddim = 1; end
            tf = all(ismember(fldname, o.fields{flddim}));
        end
        
        function tf = iscompatible(o, varargin)
            dims = cellfun(@(x)x.ndims, [o varargin]);
            tf = all(dims == dims(1)) && isaligneddates(o, varargin{:});
            for i = 1:length(varargin)
                for n = 1:dims(1)-1
                    if ~tf, break; end  % shortcut
                    tf = tf & isequal(sort(o.fields{n}), sort(varargin{i}.fields{n}));
                end
            end
        end
        
        function tf = isempty(o)
            tf = isempty(o.data);
        end
        
        function tf = isequal(varargin)
            tf = cellfun(@(x)isa(x,'xts'), varargin);
            if all(tf)
                tf = isaligneddata(varargin{:});
                data = varargin{1}.data;
                for i = 2:length(varargin)
                    if ~tf, break; end  % shortcut
                    tf = tf & isequal(data, varargin{i}.data);
                end
            else
                tf = false;
            end
        end
        
        function tf = isequalwithequalnans(varargin)
            tf = cellfun(@(x)isa(x,'xts'), varargin);
            if all(tf)
                tf = isaligneddata(varargin{:});
                data = varargin{1}.data;
                for i = 2:length(varargin)
                    if ~tf, break; end  % shortcut
                    tf = tf & isequalwithequalnans(data, varargin{i}.data);
                end
            else
                tf = false;
            end
        end
        
        function tf = issorted(o)
            tf = all(diff(o.dates) > 0);
        end
        
        function varargout = size(o, varargin)
            varargout = cell(1, max(nargout,1));
            [varargout{:}] = size(o.data, varargin{:});
        end
        
        function len = length(o)
            len = length(o.dates);
        end
        
        function mat = fts2mat(o)
            mat = o.data;
        end
        
        %% Lag and lead functions
        function o = lagts(o, nperiod, padmode)
            if nargin < 3, padmode = 0; end
            if nargin < 2, nperiod = 1; end
            FTSASSERT(nperiod >= 0, 'nperiod must be >= 0');
            newdesc = ['LAGTS (' num2str(nperiod) ') on ', o.desc];
            o.data(nperiod+1:end,:) = o.data(1:end-nperiod,:); % it's ok even for 3+ dimensional array
            o.data(1:nperiod,:) = padmode;
            o.desc = newdesc;
        end
        
        function o = leadts(o, nperiod, padmode)
            if nargin < 3, padmode = 0; end
            if nargin < 2, nperiod = 1; end
            FTSASSERT(nperiod >= 0, 'nperiod must be >= 0');
            newdesc = ['LEADTS (' num2str(nperiod) ') on ', o.desc];
            o.data(1:end-nperiod,:) = o.data(nperiod+1:end,:);
            o.data(end-nperiod+1:end,:) = padmode;
            o.desc = newdesc;
        end
        
        %% Operators
        function o = cat(dim, o, varargin)
            if dim == 1
                o = vertcat(o, varargin{:});
                return;
            end
            
            nd = cellfun(@(x)x.ndims, [{o} varargin]);
            %%%%FTSASSERT(all(nd==nd(1)), 'Number of dimensions must be the same for all arguments');
            FTSASSERT(isaligneddates(o, varargin{:}), 'dates of xts to be merged not aligned');
            for i = 2:max(nd)
                if i == dim, continue; end
                FTSASSERT(isalignedfields(o, varargin{:}, i-1),...
                    ['CAT arguments dimensions (dim ' num2str(i) ') are not consistent']);
            end
            
            % traling dimensions of size 1 assigned a fieldname equal to o.desc
            if dim > nd(1), o.fields(nd(1):dim-1) = {{o.desc}}; end
            for i = 1:nargin-2
                o.data = cat(dim, o.data, varargin{i}.data);
                % traling dimensions of size 1 assigned a fieldname equal to o.desc
                if dim > nd(i+1), varargin{i}.fields(nd(i+1):dim-1) = {{varargin{i}.desc}}; end
                o.fields{dim-1} = [o.fields{dim-1} varargin{i}.fields{dim-1}];
            end
            [fld, ~, n] = unique(o.fields{dim-1});
            
            for i = 1:length(fld)
                idx = n == i;
                count = sum(idx);
                if count > 1
                    o.fields{dim-1}(idx) = mat2cell(strcat(fld{i}, num2str((1:count)','_%d')), ones(count,1));
                end
            end
            o.fields{dim-1} = strtrim(o.fields{dim-1});
            o = checkFields(o);
            if dim > 2, o = upcast(o); end
        end
        
        %%% Concatenation ([]) Operators
        function o = horzcat(o, varargin)   %[xts1,xts2,...,xtsn]
            o = cat(2, o, varargin{:});
        end
        
        function o = vertcat(o, varargin)   %[xts1;xts2;...;xtsn]
            FTSASSERT(isalignedfields(o, varargin{:}), 'fields of xts to be merged not aligned');
            
            for i = 1:nargin-1
                o.data = [o.data; varargin{i}.data];
                o.dates = [o.dates; varargin{i}.dates];
                if o.freq ~= varargin{i}.freq
                    o.freq = 0;  % becomes unknown
                end
            end
            [o.dates, m, n] = unique(o.dates, 'first');  % also sorting
            if length(m) ~= length(n)
                warning('xts:vertcat:DuplicateDates', ...
                    'Duplicated dates detected when vertically mergeing xts objects (first data available in xts list used)');
            end
            subs = repmat({':'}, 1, o.ndims-1);
            o.data = o.data(m,subs{:});
        end
        
        %%%% Relational Operators
        function result = ge(lhs, rhs)  % >=
            result = biftsfun(lhs, rhs, @ge);
        end
        
        function result = gt(lhs, rhs)  % >
            result = biftsfun(lhs, rhs, @gt);
        end
        
        function result = le(lhs, rhs)  % <=
            result = biftsfun(lhs, rhs, @le);
        end
        
        function result = lt(lhs, rhs)  % <
            result = biftsfun(lhs, rhs, @lt);
        end
        
        function result = eq(lhs, rhs)  % ==
            result = biftsfun(lhs, rhs, @eq);
        end
        
        function result = ne(lhs, rhs)  % ~=
            result = biftsfun(lhs, rhs, @ne);
        end
        
        function result = and(lhs, rhs) % &
            result = biftsfun(lhs, rhs, @and);
        end
        
        function result = or(lhs, rhs) % |
            result = biftsfun(lhs, rhs, @or);
        end
        
        %%% Uniary Arithmetic Operators
        function o = not(o)         % ~
            o = uniftsfun(o, @not);
        end
        
        function o = uminus(o)      % - (uniary)
            o = uniftsfun(o, @uminus);
        end
        
        function o = uplus(o)       % + (uniary)
            o = uniftsfun(o, @uplus);
        end
        
        %%% Binary Arithmetic Operators
        function res = minus(a, b)    % -
            res = biftsfun(a, b, @minus);
        end
        
        function res = plus(a, b)     % +
            res = biftsfun(a, b, @plus);
        end
        
        %%%% It's weird that *, \, / actually perform dotted (element-by-element) operation
        function res = mrdivide(a, b) % /  equivlent to ./
            res = biftsfun(a, b, @rdivide);
        end
        
        function res = rdivide(a, b)  % ./ (actually the same as mrdivide for fints
            res = biftsfun(a, b, @rdivide);
        end
        
        function res = mtimes(a, b)   % * equivlent to .*
            res = biftsfun(a, b, @times);
        end
        
        function res = times(a, b)   % *
            res = biftsfun(a, b, @times);
        end
        
        function res = power(lhs, rhs)
            res = biftsfun(lhs, rhs, @power);
        end
        
        %% Mostly used Matlab functions
        %%% NAN functions, all return ordinary matrix, inconsistent to their non-nan counterparts
        function c = nancov(o, varargin)
            % only valid for 2-D but I still keep it here since Matlab will give appropriate msg
            c = varftsfun(@nancov, o, varargin{:});
        end
        
        function varargout = nanmax(o, varargin)
            varargout = cell(1, max(nargout,1));
            [varargout{:}] = varftsfun(@nanmax, o, varargin{:});
        end
        
        function varargout = nanmin(o, varargin)
            varargout = cell(1, max(nargout,1));
            [varargout{:}] = varftsfun(@nanmin, o, varargin{:});
        end
        
        function m = nanmean(o, dim)
            if nargin < 2, dim = 1; end
            m = varftsfun(@nanmean, o, dim);
        end
        
        function y = nanmedian(o, dim)
            if nargin < 2, dim = 1; end
            y = varftsfun(@nanmedian, o, dim);
        end
        
        function y = nansum(o, dim)
            if nargin < 2, dim = 1; end
            y = varftsfun(@nansum, o, dim);
        end
        
        function y = nanstd(o, varargin)
            y = varftsfun(@nanstd, o, varargin{:});
        end
        
        function y = nanvar(o, varargin)
            y = varftsfun(@nanvar, o, varargin{:});
        end
        
        %%% var/cov/corrcoef functions, all return a ordinary matrix
        function y = var(o, varargin)
            y = varftsfun(@var, o, varargin{:});
        end
        
        function [r,p,rlo,rup] = corrcoef(o, varargin)
            % Only valid for 2-D
            [r, p, rlo, rup] = varftsfun(@corrcoef, o, varargin{:});
        end
        
        function xy = cov(o, varargin)
            % Only valid for 2-D
            xy = varftsfun(@cov, o, varargin{:});
        end
        
        %%% These function return another xts object
        function o = isnan(o)
            o = ret_mat_fun(o, @isnan, 'IsNaN of ');
        end
        
        function o = isinf(o)
            o = ret_mat_fun(o, @isinf, 'IsInf of ');
        end
        
        function o = cumsum(o)
            o = ret_mat_fun(o, @(x)cumsum(x,1), 'CUMSUM of ');
        end
        
        function o = diff(o)
            o.dates(1) = [];
            o = ret_mat_fun(o, @(x)diff(x,1), 'DIFF of ', '', o.dates);
        end
        
        function o = exp(o)
            o = ret_mat_fun(o, @exp, 'EXP of ');
        end
        
        function o = log(o)
            o = ret_mat_fun(o, @log, 'LOG of ');
        end
        
        function o = log10(o)
            o = ret_mat_fun(o, @log10, 'LOG10 of ');
        end
        
        function o = log2(o)
            o = ret_mat_fun(o, @log2, 'LOG2 of ');
        end
        
        function o = abs(o)
            o = ret_mat_fun(o, @abs, 'ABS of ');
        end
        
        %% Resampling Functions
        function o = convertto(o, freq, varargin)
            option.calcMethod = 'nearest';
            s = warning('query' ,'VAROPTION:UNRECOG');
            warning('off', 'VAROPTION:UNRECOG');
            option = Option.vararginOption(option, {'CalcMethod'}, varargin{:});
            warning(s.state, 'VAROPTION:UNRECOG');
            ds = Freq.genDateSeries(o.dates(1), o.dates(end), freq, option.varargin{:});
            o = aligndates(o, ds, 'CalcMethod', option.calcMethod);
            o.freq = freq;
        end
        
        function o = toannual(o, varargin)
            o = convertto(o, 'A', varargin{:});
        end
        
        function o = todaily(o, varargin)
            o = convertto(o, 'D', varargin{:});
        end
        
        function o = tomonthly(o, varargin)
            o = convertto(o, 'M', varargin{:});
        end
        
        function o = toquarterly(o, varargin)
            o = convertto(o, 'Q', varargin{:});
        end
        
        function o = tosemi(o, varargin)
            o = convertto(o, 'S', varargin{:});
        end
        
        function o = toweekly(o, varargin)
            o = convertto(o, 'W', varargin{:});
        end
        
        %% Engine functions
        function o = ret_mat_fun(o, fun, desc, varargin)
            % varargin could be anything to be passed into uniftsfun
            newdesc = [desc o.desc];
            o = uniftsfun(o, fun, varargin{:});
            o.desc = newdesc;
        end
        
        function varargout = varftsfun(fun, o, varargin)
            varargout = cell(1, max(nargout,1));
            % o may or may not be a xts. If it's not, varargin{1} must be a xts.
            if nargin > 2 && isa(varargin{1}, 'xts')
                f = @(x,y) fun(x,y,varargin{2:end});
                [varargout{:}] = biftsfun(o, varargin{1}, f, false);
            else  % in this case, xts must be a myfints, otherwise matlab can not run to here
                f = @(x) fun(x,varargin{:});
                [varargout{:}] = uniftsfun(o, f, false);
            end
        end
        
        function [o, varargout] = uniftsfun(o, fun, varargin)
            % Syntax:
            %    oxts = uniftsfun(ixts, fun_handle)
            %    oxts = uniftsfun(ixts, fun_handle, fieldname)
            % where
            %    ixts       : xts object to be operated on
            %    fun_handle : operation to be performed on ixts
            %    fieldname  : Specifies what field names should be in the returned
            %                 xts object ofts.
            %                 fieldname should be a char vector (representing a string),
            %                 a cell vector of strings (representing fields for one dimension)
            %                 or a cell vector of cell vectors of strings (each element of which
            %                 is a cell of strings representing fields for a dimension).
            %                 The number of field names for one dimension provided should be 1
            %                 or matching the result returned by fun_handle.
            %
            %                 In case of one field name provided and returning multiple fields
            %                 by fun_handle, the field name will be appended by a counter.
            %                 If number of fields names beyond 1 and not matching the
            %                 result of fun_handle (not equal the number of columns returned
            %                 by fun_handle), an error will be raised.
            %
            %               * By DEFAULT, the fieldname in ixts will be used.
            %                 HOWEVER, NO GUARANTEE the default value works;
            %                 In this case, caller should provide appropriate
            %                 fieldname.
            %
            %                 For most cross-sectional operation (dim = 1),
            %                 you should provide a fieldname since the returned usually
            %                 has less than the orignal number of columns (mostly only
            %                 one column, such as mean, sum, etc. on column dimension)
            %                 For most time-series operation (dime = 2),
            %                 you don't need to provide fieldnames since most of these
            %                 operation returned something having the same number of
            %                 columns as operand (still, consider mean, sum on row
            %                 dimention).
            %
            %               * Generally speaking, operation along a specified dimension
            %                 usually removes that dimension from the result.
            %                 For instance, mean(A,1) will remove row(1st) dimension,
            %                 and mean(A,2) remove the column(2nd) dimension.
            %
            %               * HOWEVER, SEE ftsmovfun() for a special case where dim == 1
            %                 and the returned has the same size as operand.
            %
            %          oxts : result returned. Usually, it's still a xts object
            %                 having the similiar structure as ixts (see explanation about
            %                 fieldname above).
            %                 HOWEVER, in case of
            %                _the result returned by fun_handle has different number
            %                 of rows as that of inputted ifts_,
            %                    * if the returned row number is 1,
            %                      oxts uses last date in ifts as its date;
            %                    * otherwise, directly return the result (type of matrix)
            %                      instead of xts object.
            varargout = cell(1, nargout-1);
            [newdata, varargout{:}] = fun(o.data);
            o = xtsreturn(o, newdata, varargin{:}); % varargin either null or contains fieldname
        end
        
        function [o, varargout] = biftsfun(lhs, rhs, fun, varargin)
            %    Core function performing actions on at least two xts objects.
            %    (More xts possible, all depends on fun_handle.
            % Syntax:
            %    oxts = biftsfun(lhs, rhs, fun_handle)
            %    oxts = biftsfun(lhs, rhs, fun_handle, fieldname)
            % where
            %    lhs, rhs   : operands (left and right in case of fun_handle being
            %                 bi-operand operator) on which fun_handle to be performed.
            %                 One of them surely is myfinys object (otherwise MATLAB
            %                 WON'T call this function). The other can be anything
            %                 fun_handle allowed (e.g., a scalar, matrix, or xts
            %                 object, etc.)
            %                 lhs and rhs must be compatible in the sense of:
            %                   * if both are xts objects, iscompatible returns true
            %                   * if only one of them is of type xts, the matrix
            %                     form of them are allowed by fun_handle
            %    fun_handle : operation to be performed on lhs and rhs
            %    fieldname  : similiar to uniftsfun
            %          ofts : result returned. Usually, it's still a xts object
            %                 having the similiar structure as inputted xts object(s)
            %                 (either lhs or rhs). (see explanation about fieldname above).
            %                 HOWEVER, in case of
            %                _the result returned by fun_handle has different number
            %                 of rows as that of inputted xts object(s)_,
            %                    * if the returned row number is 1,
            %                      ofts uses last date in ifts as its date;
            %                    * otherwise, directly return the result (type of matrix)
            %                      instead of xts object.
            %
            %  Some benefits of using this function:
            %    * check compability of lhs and rhs and align fields if necessary
            %      in one place
            %    * pack the return in one place
            %    * 5 > xts_obj, meanif(magic(5), xts_condition) possible.
            %      (Before this, user be restricted to write only
            %          xts_obj < 5  not 5 > xts_obj
            %       and
            %       in meanif(), the first argument must be a xts object)
            if isa(lhs, 'xts')
                if isa(rhs, 'xts')
                    FTSASSERT(isaligneddata(lhs, rhs),'LHS and RHS are not aligned');
                    rhs = rhs.data;
                end
                o = lhs;
                lhs = lhs.data;
            else
                % rhs must be type of 'xts' and lhs is normal matlab matrix or scalar
                o = rhs;
                rhs = rhs.data;
            end
            
            varargout = cell(1, nargout-1);
            [newdata, varargout{:}] = fun(lhs, rhs);
            o = xtsreturn(o, newdata, varargin{:}); % varargin either be null or fieldname
        end
        
        function ofts = multiftsfun(varargin)
            fun = varargin{end};
            varargin(end) = [];
            
            FTSASSERT(isaligneddata(varargin{:}), 'arguments not aligned');
            
            nxts = length(varargin);
            sz = size(varargin{1});
            stackeddata = NaN([sz nxts]);
            fldsubs = repmat({':'}, 1, length(sz));
            for i = 1:nxts
                stackeddata(fldsubs{:},i) = varargin{i}.data;
            end
            
            ret = fun(stackeddata); % last dimension of stackeddata must be disappeared
            
            % Pack result into xts object
            ofts = xtsreturn(varargin{1}, ret);
        end
        
        function o = bsxfun(fun, lhs, rhs)
            o = [];
            if isa(lhs, 'xts')
                o = lhs;
                if isa(rhs, 'xts')
                    n = max(lhs.ndims, rhs.ndims) - 1;
                    flds = cell(n,1);  % column vector is a convention
                    nL = zeros(1,n);
                    nR = zeros(1,n);
                    nL(1:lhs.ndims-1) = cellfun(@(x) length(x), lhs.fields);
                    nR(1:rhs.ndims-1) = cellfun(@(x) length(x), rhs.fields);
                    flds(1:lhs.ndims-1) = lhs.fields;
                    flds(nL < nR) = rhs.fields(nL < nR);
                else
                    flds = lhs.fields;
                end
                lhs = lhs.data;
            end
            if isa(rhs, 'xts')
                if ~isa(o, 'xts')
                    o = rhs;
                    flds = rhs.fields;
                end
                rhs = rhs.data;
            end
            
            o = xtsreturn(o, bsxfun(fun, lhs, rhs), flds);
        end
        
        function o = backfill(o, lookbackperiod, mode)
            if ~any(isnan(o.data(:)))
                return;
            end
            
            if nargin < 3, mode = 'row'; end;
            if nargin < 2, lookbackperiod = inf; end
            FTSASSERT(lookbackperiod >= 0);
            
            mat = o.data;
            T = size(mat,1);
            for i = T:-1:1
                for j = 1:min(lookbackperiod,i-1)
                    nanidx = isnan(mat(i,:));
                    if strcmpi(mode, 'row')
                        if all(nanidx)
                            mat(i,:) = mat(i-j,:);
                        end
                    elseif strcmpi(mode, 'entry')
                        if any(nanidx)
                            mat(i,nanidx) = mat(i-j,nanidx);
                        end
                    end
                end
            end
            o = xtsreturn(o, mat);
        end  % of backfill()
        
        function o = forwardfill(o, lookfwdperiod, mode)
            if ~any(isnan(o.data(:)))
                return;
            end
            
            if nargin < 3, mode = 'row'; end;
            if nargin < 2, lookfwdperiod = inf; end
            FTSASSERT(lookfwdperiod >= 0);
            
            mat = o.data;
            T = size(mat,1);
            for i = 1:T
                for j = 1:min(lookfwdperiod,T-i)
                    nanidx = isnan(mat(i,:));
                    if strcmpi(mode, 'row')
                        if all(nanidx)
                            mat(i,:) = mat(i+j,:);
                        end
                    elseif strcmpi(mode, 'entry')
                        if any(nanidx)
                            mat(i,nanidx) = mat(i+j,nanidx);
                        end
                    end
                end
            end
            
            o = xtsreturn(o, mat);
        end
        
        function o = fill(o, lookperiod, mode)
        % fill has similiar functionality as backfill() and forwardfill()
        % except it in most cases is faster than those two functions.
        % Here's the general guidelines in deciding which one should be used:
        %   1. If you don't know or want to know about anything about filling details,
        %       use fill().
        %   2. If o has only a few NaNs to be filled, use fill() since it will 
        %       way faster than backfill() and forwardfill().
        %   3. If o has a lot of NaNs and need to be filled along many periods 
        %       (like |lookperiod| > 40, use fill() since it should be faster than 
        %        backfill() and forwardfill().
        %   4. If o need to be filled along all periods (i.e., |lookperiod| >= size(o,1)),
        %      use fill() since it's exceptionally fast.
        %   5. if o has a lot of NaNs but need to be filled only a few periods
        %        (|lookperiod| < 40), use backfill() and forwardfill().
        %
        %  Note that lookperiod > 0 means back-filling, 
        %  while lookperiod < 0 means forward-filling.
            if nargin < 3, mode = 'row'; end;
            if nargin < 2, lookperiod = inf; end
            
            mat = o.data;
            [T,N] = size(mat);

            isFwd = false;
            if lookperiod < 0
                mat = mat(T:-1:1, :);
                lookperiod = - lookperiod;
                isFwd = true;
            elseif lookperiod == 0
                return;
            end
            
            nanidx = isnan(mat);
            lookperiod = min(T-1, lookperiod);
       
            if strcmpi(mode, 'row')
                I = find(all(reshape(nanidx,T,N), 2));
                for i = 1:lookperiod
                    I(I==i) = [];
                    if isempty(I)
                        break;
                    else
                        nanidx = ismember(I-1,I);
                        mat(I,:) = mat(I-1,:);
                        I = I(nanidx);
                    end
                end
            elseif strcmpi(mode, 'entry')
                nanloc = find(nanidx);
                [nanline,~] = ind2sub([T N], nanloc);
                if lookperiod == T-1  % gonna to fill along over all periods
                    nanloc(nanline == 1) = [];  % first row we can not backfill because no further backward
                    for i = 1:numel(nanloc)
                        mat(nanloc(i)) = mat(nanloc(i)-1);
                    end
                else
                    for i = 1:lookperiod
                        rmidx = nanline == i;  % first row we can not backfill because no further backward
                        nanline(rmidx) = [];
                        nanloc(rmidx) = [];
                        if isempty(nanline)
                            break;
                        else
                            A = mat(nanloc - 1);
                            mat(nanloc) = A;   % filling
                            nanidx = isnan(A); % some already not nan, remove them
                            nanline = nanline(nanidx); % narrow down filled range
                            nanloc = nanloc(nanidx);
                        end
                    end
                end
            else
                FTSASSERT(false, ['Unrecognized mode: ' mode]);
            end
            
            if isFwd
                mat = mat(T:-1:1, :);
            end
            
            o.data = mat;
        end
        
    end  % of methods
    
    methods (Static)
        function tf = isproperty(fld)
            tf = ismember(fld, {'dates', 'freq', 'desc', 'unit'});
        end
    end
end % of classdef

