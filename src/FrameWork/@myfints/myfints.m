classdef myfints < xts
    methods
        %% Constructor
        function o = myfints(varargin)
            % Syntax: Constructor syntax is the same as that of fints class
            %	fts = myfints()
            %	fts = myfints(dates_and_data)
            %	fts = myfints(dates, data)
            %	fts = myfints(dates, data, datanames)
            %	fts = myfints(dates, data, datanames, freq)
            %	fts = myfints(dates, data, datanames, freq, desc)
            %	fts = myfints(dates, data, datanames, freq, desc, unit)
            
            FTSASSERT(nargin <= 6, 'Too many arguments in construcing of myfints');
            if nargin == 1
                date_and_data = varargin{1};
                FTSASSERT(size(date_and_data,2) > 1, ['At least 2 columns needed in ' inputname(1) ' where the 1st column is dates']);
                varargin = {date_and_data(:,1), date_and_data(:,2:end)};
            end
                    
            o = o@xts(varargin{:});
            FTSASSERT(o.ndims == 2, 'For number of dimension exceeding 2 please use xts');
        end
        
        %% Standard operations on myfints
        function fh = plot(fts, varargin)
            fh = tsplot(fts, varargin{:});
        end
        
        function ret = getfield(fts, field, dates_)
        % ret = getfield(fts, field);
        % ret = getfield(fts, dates_);
            if nargin < 3, dates_ = ':'; end
            if fts.isproperty(field)
                ret = getfield@xts(fts, field, dates_);
            else
                FTSASSERT(ischar(field), [inputname(2) ' should be a char specifying the name of field to be retrieved']);
                s.type = '()'; s.subs = {dates_, field};
                ret = subsref(fts, s);
            end
        end
        
        function fts = setfield(fts, flds, varargin)
            FTSASSERT(nargin <= 4, 'too many arguments');

            if length(varargin) > 1
                dates_ = varargin{1};
                v = varargin{2};
            else
                dates_ = ':';
                v = varargin{1};
            end
            
            if ischar(flds)
                if fts.isproperty(flds)
                    fts = setfield@xts(fts, flds, varargin{:});
                    return;
                end
                if ~isfield(fts, flds)  % add a new field to the fts
                    fts = horzcat(fts, myfints(fts.dates, NaN(length(fts),1), flds));
                    if isa(v, 'myfints')
                        v = fts2mat(v);  %%% Too sad I have to relax the field align checking here for compatibility with fints
                    end
                end
            end
            
            s.type = '()'; s.subs = {dates_, flds};
            fts = subsasgn(fts, s, v);
        end
        
%         function tsmat = fts2mat(fts, varargin)
%         % tsmat = fts2mat(tsobj)
%         % tsmat = fts2mat(tsobj, datesflag)
%         % tsmat = fts2mat(tsobj, seriesnames)
%         % tsmat = fts2mat(tsobj, datesflag, seriesnames)
%             n = length(varargin);
%             FTSASSERT(n<=2, 'too many arguments');
%             
%             dateflag = 0;
%             seriesnames = fts.fields{1};
%             for i = 1:n
%                 if isnumeric(varargin{i}) || islogical(varargin{i})
%                     dateflag = varargin{i};
%                 else
%                     FTSASSERT(iscell(varargin{i}) || ischar(varargin{i}), [inputname(i+1) ': invalid argument']);
%                     seriesnames = varargin{i};
%                 end
%             end
%             
%             [tf, loc] = ismember(seriesnames, fts.fields{1});
%             if dateflag == 0
%                 tsmat = fts.data(:,loc(tf));
%             else
%                 tsmat = [fts.dates fts.data(:,loc(tf))];
%             end
%         end
       
        %%% These functions return a structure, one evidence of inconsistence in matlab's fints
        function ftsmax = max(fts)
            ftsmax = ret_one_row_fun(fts, @(x)max(x,1));
        end
        
        function ftsmin = min(fts)
            ftsmin = ret_one_row_fun(fts, @(x)min(x,1));
        end
        
        function ftsmean = mean(fts)
            ftsmean = ret_one_row_fun(fts, @(x)mean(x,1));
        end
        
        function ftsstd = std(fts, flag)
            ftsstd = ret_on_row_fun(fts, @(x)std(x,flag));
        end
        
        %%% These functions perform on row-side (cross-sectional) and return a new myfints, all ignore NaNs
        function ofts = csmax(fts)
            ofts = uniftsfun(fts, @(x)nanmax(x,[],2), 'csmax');
        end
        
        function ofts = csmin(fts)
            ofts = uniftsfun(fts, @(x)nanmin(x,[],2), 'csmin');
        end

        function ofts = csmean(fts)
            ofts = uniftsfun(fts, @(x)nanmean(x,2), 'csmean');
        end
        
        function ofts = csmedian(fts)
            ofts = uniftsfun(fts, @(x)nanmedian(x,2), 'csmedian');
        end
        
        function ofts = cssum(fts)
            ofts = uniftsfun(fts, @(x)nansum(x,2), 'cssum');
        end

        function ofts = csstd(fts)
            ofts = uniftsfun(fts, @(x)nanstd(x,0,2), 'csstd');
        end
        
        function ofts = csvar(fts)
            ofts = cscov(fts, fts, 'ignorenan');
            ofts = chfield(ofts, 'cscov', 'csvar');
        end
        
        function ofts = csnorm(fts)  % cross-sectional normalize to sum to 1
            ofts = uniftsfun(fts, @(x)bsxfun(@rdivide, x, nansum(x,2)), 'csnorm');
        end
        
        %% Some more complicated functions
        function fts = tsmovavg(fts, mode, win)
            f = @(x) tsmovavg(x, mode, win, 1);
            fts = uniftsfun(fts, f);
        end
        
        function fts = macd(fts, series_name)
            if nargin < 2, series_name = ':'; end
            s.type = '()'; s.subs = {':', series_name};
            fts = subsref(fts, s);
            [macdvec, nineperma] = macd(fts.data, 1);
            fts = ftsreturn(fts, [macdvec, nineperma], {'MACDLine' 'NinePerMA'});
        end
        
        %% Engine functions
        function stret = ret_one_row_fun(fts, fun)
            v = fun(fts.data);
            for i = 1:length(fts.fields)
                stret.(fts.fields{i}) = v(i);
            end
        end
    end
end  % of classdef
