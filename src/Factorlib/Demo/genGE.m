function gen(srcFolder, destFolder)
    leadingSpaces = '        ';
    
    if nargin < 2
        error('Usage: gen srcFolder destFolder');    
    end
    if srcFolder(end) ~= '\' && srcFolder(end) ~= '/'
        srcFolder(end+1) = '/';
    end
    if destFolder(end) ~= '\' && destFolder(end) ~= '/'
        destFolder(end+1) = '/';
    end
    
    trace = TRACE('Scanning %s\n', srcFolder);
    
    files = dir(srcFolder);
    if isempty(files)
        trace.printf('Nothing in %s!\n', srcFolder);
        return;
    end
    
    counter = 0;
    for i = 1:length(files)
        f = files(i);    
        if f.isdir...
           || isempty(regexp(f.name, '\.m', 'ONCE'))... % not .m file
           || f.name(1) ~= 'F'...               % ignore constructor
           || length(f.name) < 6 ...
           || isnan(str2double(f.name(2:6)))
            continue;
        end
        
        trace.printf('%s', [f.name '...']);
        funName = f.name(1:end-2);
        fr = fopen([srcFolder f.name], 'r');
        body = [leadingSpaces 'dates = genDateSeries(startDate, endDate, targetFreq, ''Busday'', 0);\n\n'];
        enter = false;
        runDate = '';
        factorId = '';
        factorTS = '';
        line = getline(fr);
        firstline = true;
        while ischar(line)
            s = '';
            line = strtrim(line);
            if ~isempty(runDate)
                line = regexprep(line, ['\<' runDate '\>'], 'endDate');
            end
            if ~isempty(factorTS)
                line = regexprep(line, ['\<' factorTS '\>'], 'factorTS');
            end
            if isempty(line) || line(1) == '%'
            elseif enter
                if ~isempty(regexp(line, '^\<end\>', 'ONCE'))
                    enter = false;
                end
            elseif ~isempty(regexp(line, '^if\s*~iscell', 'ONCE'))
                enter = true;
            elseif ~isempty(regexp(line, ['^\s*function\>.*\<' funName '\>'], 'ONCE')) ||...
                   (~isempty(regexp(line, '^\s*function\>', 'ONCE')) && firstline)
                b = strfind(line,'=') + 1;
                e = strfind(line(b:end), '(')-2+b;
                funName_ = sscanf(line(b:e), '%s', 1);
                if ~strcmpi(funName, funName_)
                    warning([f.name ': fun name different from filename']);
                    line = regexprep(line, funName_, funName);
                end
                iArgs = parseInArgs(line);
                oArgs = parseOutArgs(line, funName);
                runDate = iArgs{1};
                isProd  = iArgs{5};
                factorTS = oArgs{3};
                factorId = oArgs{2};
                priceItem = '';
                counter = counter + 1;
            elseif ~isempty(regexp(line, '\<runSP\>', 'ONCE'))
                iArgs = parseInArgs(line);
                oArgs = parseOutArgs(['function ' line], 'runSP');
                itemid = iArgs{3};
                posn = regexp(itemid, '''');
                if length(posn) == 2
                    itemid = itemid(posn(1):posn(2));
                    if itemid(2) == 'D'
                        s = [oArgs{1} ' = LoadRawItemTS(secIds, ' itemid ', startDate, ' iArgs{6} ', targetFreq);'];
                    else
                        query = ['select id from dataqa.api.itemmstr where sourceId = ' itemid];
                        itemid = runSP('QuantStrategy', query, {});
                        FTSASSERT(ischar(itemid.id));
                        itemid = ['''' itemid.id ''''];
                        s = [oArgs{1} ' = LoadRawItemTS(secIds, ' itemid ', startDate, ' iArgs{5} ', targetFreq);'];
                    end
                    if ismember(itemid, {'''D000112587''', '''D000110013''', '''D000310017''', '''D000453775''', '''D000410126''', '''D000310006'''})
                        if ~isempty(priceItem) && ~strcmp(priceItem, oArgs{1})
                            warning('Multiple DIFFERENT PRICE items found!');
                        end
                        priceItem = oArgs{1};
                    end
                else
                    s = line;
                end
            elseif ~isempty(regexp(line, '\<secid_datamap\>', 'ONCE'))
                iArgs = parseInArgs(line);
                oArgs = parseOutArgs(['function ' line], 'secid_datamap');
                oa = sprintf('%s,', oArgs{2:end});
                oa(end) = [];
                if length(oArgs(2:end)) > 1
                    oa = ['[' oa ']'];
                end
                ia = sprintf('%s,', iArgs{2:end});
                s = [oa ' = aligndata(' ia 'dates);'];
            elseif ~isempty(regexp(line, '\<repmat\>', 'ONCE'))
                %iArgs = parseInArgs(line);
                oArgs = parseOutArgs(['function ' line], 'repmat');
                if ~strcmp(oArgs{1}, factorId)
                    s = line;
                end
            elseif ~isempty(regexp(line, ['^if\s.*' isProd], 'ONCE'))
                s = 'if nargout > 1 %% live version';
            else
                s = line;
            end
            if ~isempty(s)
                body = [body leadingSpaces s '\n'];
            end
            line = getline(fr);
            firstline = false;
        end
        fclose(fr);
        if strcmp(body(end-7:end-2), 'return')
            body(end-7:end) = [];
            while body(end) == ' '
                body(end) = [];
            end
        end
        if isempty(priceItem)
            priceMatter = '[]';
        else
            priceMatter = ['LatestDataDate(' priceItem ')'];
        end
        body = [body '\n' leadingSpaces 'if nargout > 1 %% live version\n'...
                leadingSpaces '    priceDateStruct = ' priceMatter ';\n' leadingSpaces 'end\n'];
        genClass(destFolder, funName, body);
        trace.done;
    end
end

function args = parseInArgs(line)
% analysis arguments
   args = {};
   delimters = sprintf('\f\n\r\t\v ,)');
   nLen = length(line);
   
   for i = 1:nLen
       if line(i) == '(', break; end
   end
   if i == nLen % no arg list at all
       return;
   end
   
   i = i + 1;  % skip '('
   
   for counter = 1:nLen
       for i = i:nLen
           if ~ismember(line(i), delimters), break; end
       end
       if i == nLen, break; end

       s = i;
       for i = i:nLen
           if ismember(line(i), delimters), break; end
       end
       args{counter} = line(s:i-1); %#ok<AGROW>
       if i == nLen, break; end
   end
end

function args = parseOutArgs(line, funName)
% analysis arguments
   args = {};
   delimters = sprintf('\f\n\r\t\v ,[]=');
   
   s = regexp(line, '\<function\>');
   e = regexp(line, ['\<' funName '\>']);
   FTSASSERT(~isempty(s) && ~isempty(e), 'function line located error');

   line = line(s+length('function'):e);
   nLen = length(line);

   i = 1;
   for counter = 1:nLen
       for i = i:nLen
           if ~ismember(line(i), delimters), break; end
       end
       if i == nLen, break; end

       s = i;
       for i = i:nLen
           if ismember(line(i), delimters), break; end
       end
       args{counter} = line(s:i-1); %#ok<AGROW>
       
       if i == nLen, break; end
   end
end

function genClass(folder, funName, body)
    template = [...
        'classdef ' funName ' < GlobalEnhanced\n' ...
        'methods (Access = protected, Static)\n' ...
        '    function [factorTS, priceDateStruct] = build(secIds, startDate, endDate, targetFreq)\n' ...
        body ...
        '    end\n\n' ...
        '    function [factorTS, priceDateStruct] = buildLive(secIds, endDate)\n' ...
        '        [factorTS,priceDateStruct] = ' funName '.build(secIds, endDate, endDate, ''M'');\n' ...
        '    end\n' ...
        'end\nend\n'];

    fid = fopen([folder funName '.m'], 'w');
    fprintf(fid, template);
    fclose(fid);
end

function line = getline(fid)
    line = fgets(fid);
    if ischar(line)
        l = strtrim(line);
        if length(l)>3 && strcmp(l(end-2:end),'...')
            line = [l(1:end-3) strtrim(fgets(fid))];
        end
    end
end
