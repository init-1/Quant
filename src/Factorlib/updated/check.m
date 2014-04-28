classdef check
    %check <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:26

    properties (Access = private)
        startDate
        endDate
        isLive
    end
    
    methods
        function o = check(startDate, endDate, isLive)
            if nargin < 1
                error('Usage: check codeFolder startDate [endDate] [isLive]');
            end
            if nargin < 3, isLive = true; end
            if nargin < 2, endDate = startDate; end
            
            o.startDate = startDate;
            o.endDate   = endDate;
            o.isLive    = isLive;
        end
        
        function rho = run(o, codeFolder, fname)
            if nargin < 3, fname = ''; end
            if codeFolder(end) ~= '\' && codeFolder(end) ~= '/'
                codeFolder(end+1) = '/';
            end
            
            trace = TRACE('Scanning %s\n', codeFolder);
            
            files = dir(codeFolder);
            if isempty(files)
                trace.printf('Nothing in %s!\n', codeFolder);
                return;
            end
            
            counter = 0;
            rho = cell(length(files),1);
            old = cell(size(rho));
            for i = 1:length(files)
                f = files(i);
                if f.isdir|| isempty(regexp(f.name, '\.m', 'ONCE'))... % not .m file
                   || ~strcmp(f.name(1:3), 'GE_')               % ignore constructor
                    continue;
                end
                
                counter = counter + 1;
                funName = f.name(1:end-2);
                if ~isempty(fname) && isempty(regexp(funName(4:end), fname, 'ONCE')), continue; end
                
                trace.printf('%d: %s', counter, [funName '...']);
                try
                [old{counter}, secids] = o.loadOld(funName);
                if isempty(old{counter})
                    trace.printf('skipped\n');
                    continue;
                end
                
                fun = str2func(funName);
                if o.isLive
                    new = create(fun(), secids, true, o.endDate);
                else
                    new = create(fun(), secids, false, o.startDate, o.endDate, 'M');
                end
                [old{counter}, new] = aligndata(old{counter}, new, 'M');
                rho{counter} = csrankcorr(old{counter}, new);
                rho{counter} = chfield(rho{counter}, 'cscorr', funName);
                catch e
                    disp(getReport(e));
                end
                trace.done;
            end
            
            rho = rho(1:counter);
            save('lv.mat', 'rho', 'old');
            trace.printf('%d factorts have been checked\n', counter);
        end
        
        function [old, secids] = loadOld(o, funName)
            if o.isLive
                tableName = 'glb.GLOBAL_SCRN_ML_RANK';  %commonsqlprod2.quantstrategy.
            else
                tableName = 'glb.GLOBAL_SCRN_ML_RANK_BT';
            end
            
            loc = strfind(funName,'_');
            if isempty(loc)
                old = [];
                return;
            end
            
            query = ['SELECT DISTINCT a.StockID,a.Date,a.Value FROM ' tableName ' a, fac.factormstr b WHERE a.Date BETWEEN ''' o.startDate ''' AND ''' o.endDate '''' ...
                ' AND a.ItemID=b.QSItemId and b.name=''' funName ''''];
            old = runSP('QuantStrategy', query, {});
            if isempty(old), secids = []; return; end
            secids = old.StockID;
            old = mat2fts(datenum(old.Date), old.Value, QuantId2FieldId(secids));
            old = old{1};
            old(old==-999999) = NaN;
            secids = unique(secids);
        end
    end
end
