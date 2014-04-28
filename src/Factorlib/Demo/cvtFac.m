function cvtFac(srcFolder, destFolder)
    if nargin < 2
        error('Usage: gen srcFolder destFolder');    
    end
    if srcFolder(end) ~= '\' && srcFolder(end) ~= '/'
        srcFolder(end+1) = '/';
    end
    if destFolder(end) ~= '\' && destFolder(end) ~= '/'
        destFolder(end+1) = '/';
    end
    
    TRACE('Scanning %s\n', srcFolder);
    
    files = dir(srcFolder);
    if isempty(files)
        TRACE('Nothing in %s!\n', srcFolder);
        return;
    end
    
    for i = 1:length(files)
        f = files(i);    
        if f.isdir || isempty(regexp(f.name, '\.m', 'ONCE')) % not .m file
            continue;
        end
        
        TRACE('%s', [f.name '...']);
        clsName = f.name(1:end-2);
        fr = fopen([srcFolder f.name], 'r');
        fw = fopen([destFolder f.name], 'w');
        level = -1;
        line = getline(fr);
        while ischar(line)
            if level <= 0 && ~isempty(regexp(line, '^\s*%', 'ONCE'))  % remove comment around classdef & build
                line = '';
            elseif level == -100
                level = 2;
            elseif level == -200
                level = 200;
            end
            
            if ~isempty(line)
                if ~isempty(regexp(line, '^\s*\<classdef\>', 'ONCE'))
%                    line = regexprep(line, '\<FacBase\>', 'FacBase');
                    line = [line char(10) clscomments(clsName)]; %#ok<AGROW>
                    level = level + 1;
                elseif ~isempty(regexp(line, '^\s*\<methods\>.*\<Static\>', 'ONCE'))
                    line = regexprep(line, '\(.*\)', '(Access = protected)');
                    level = level + 1;
                elseif ~isempty(regexp(line, '^\s*function\>.*\<build\>', 'ONCE'))
                    line = regexprep(line, '\((\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*,\s*(\w+)', '($1, $2, $3');
                    line = regexprep(line, '\<build\>\s*\(', 'build(o, ');
                    if strncmp(clsName, 'GE_', 3)
                        line = regexprep(line, '\[(\w+)\s*,\s*(\w+)\s*\]', '$1');
                    end
                    level = -100;
                elseif ~isempty(regexp(line, '^\s*function\>.*\<buildLive\>', 'ONCE'))
                    line = regexprep(line, '\<buildLive\>\s*\(', 'buildLive(o, ');
                    level = -200;
                elseif ~isempty(regexp(line, '^\<(if)|(while)|(for)|(switch)\>', 'ONCE'))
                    level = level + 1;
                elseif ~isempty(regexp(line, '^\s*\<end\>', 'ONCE'))
                    level = level - 1;
                elseif ~isempty(regexp(line, '\<LoadRawItemPIT\>', 'ONCE'))
                    line = regexprep(line, '\((\S+\s*,\s*){4,}(\S+)(\s*,\s*\S+)\)', '($1$2)');
                    line = regexprep(line, '\<LoadRawItemPIT\s*\(', 'o.loadItem(');
                elseif ~isempty(regexp(line, '\<LoadRawItemTS\>', 'ONCE'))
                    line = regexprep(line, '\((\S+\s*,\s*){3,}(\S+)(\s*,\s*\S+)\)', '($1$2)');
                    line = regexprep(line, '\<LoadRawItemTS\s*\(', 'o.loadItem(');
                elseif ~isempty(regexp(line, 'Base\.\w+\s*\(', 'ONCE'))
                    if ~isempty(regexp(line, '\<build@', 'ONCE'))
                        line = regexprep(line, '\((\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*', '($1, $2, $3, ');  % remove freq param
                    end
                    line = regexprep(line, '(\<\w+Base\>)\.(\w+)\s*\(', '$2@$1(o, ');
                elseif ~isempty(regexp(line, [clsName '\.\w+\s*\('], 'ONCE'))
                    line = regexprep(line, ['(\<' clsName '\>)\.(\w+)\s*\('], 'o.$2(');
                elseif ~isempty(regexp(line, '\<(lagts)|(leadts)\>\s*(', 'ONCE'))
                    line = regexprep(line, '\<lagts\>\s*\((\S+)\s*,\s*(\S+)\s*,', 'o.lagfts($1, ''$2M'', ');
                    line = regexprep(line, '\<leadts\>\s*\((\S+)\s*,\s*(\S+)\s*,', 'o.leadfts($1, ''$2M'', ');
                    line = regexprep(line, '\<lagts\>\s*\((\S+)\s*,\s*(\S+)\s*\)', 'o.lagfts($1, ''$2M'')');
                    line = regexprep(line, '\<leadts\>\s*\((\S+)\s*,\s*(\S+)\s*\)', 'o.leadfts($1, ''$2M'')');
                elseif ~isempty(regexp(line, '\<genDateSeries\>\s*(', 'ONCE'))
                    line = regexprep(line, '\<genDateSeries\>\s*(', 'o.genDates(');
                    line = regexprep(line, '\((\S+)\s*,\s*(\S+)\s*,\s*(\S+)', '($1, $2, o.targetFreq);    %');
                elseif strncmp(clsName, 'GE_', 3) && ~isempty(regexp(line, 'if\s*\<nargout\>', 'ONCE'))
                    nextline = getline(fr);
                    if ~isempty(regexp(nextline, '\<priceDateStruct\>', 'ONCE'));
                        nextline = getline(fr);
                        assert(~isempty(regexp(nextline, '^\s*\<end\>\s*$', 'ONCE')));
                        line = '';
                    else
                        line = regexprep(line, '\<nargout\>.*$', 'o.isLive');
                        line = [line char(10) nextline]; %#ok<AGROW>
                    end
                elseif ~isempty(regexp(line, '\<GlobalEnhanced\.loadItem\>', 'ONCE'))
                    line = regexprep(line, '\<GlobalEnhanced\>', 'o');
                    line = regexprep(line, '\(\S+\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*\S+\s*\)', '($1, $2, $3, $4)');
                    line = regexprep(line, '\(\S+\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)', '($1, $2, $3, $4)');
                end
                
                if ~isempty(line)
                    fwrite(fw, [line char(10)]);
                end
            end
            
            line = getline(fr);
        end
        fclose(fr);
        fclose(fw);
        TRACE(' done\n');
    end
end

function line = getline(fid)
    line = fgetl(fid);
    if ischar(line)
        [~,~,~,leadingspace] = regexp(line, '^\s*', 'ONCE');
        line = strtrim(line);
        if length(line)>3 && strcmp(line(end-2:end),'...')
            line = [line(1:end-3) strtrim(fgetl(fid))];
        end
        line = [leadingspace line];
    end
end

function s = clscomments(clsName)
    s = [...
        '    %' clsName   ' <a full descriptive name placed here>' char(10) '    %' char(10) ...
        '    %  Formula:' char(10) '    %' char(10) ...
        '    %  Description:' char(10) '    %' char(10)...
        '    %  Copyright 2012 ING IM AP' char(10)...
        '    %  Dates: ' datestr(now) char(10) ...
        ];
end