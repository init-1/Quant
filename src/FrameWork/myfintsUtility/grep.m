function allids = grep(directory, pattern, old, new, tr)
    if nargin < 5
        tr = @nothing;
    end
    
    if nargin < 3 || isempty(old)
        old = NaN;
        new = NaN; 
    end
    
    allids = {};
    
    if isdir(directory)
        tr('Scanning %s\n', directory);
        if directory(end) ~= '\', directory(end+1) = '\'; end
        files = dir(directory);
        if isempty(files)
            tr('nothing in %s!\n', directory);
            return;
        end
    else
        files.isdir = 0;
        files.name = directory;
        directory = '';
    end
    
    for i = 1:length(files)
        f = files(i);    
        if f.isdir 
            if f.name(1) ~= '.'
                tr('Entering %s\n', f.name);
                allids = [allids grep([directory f.name], pattern, old, new)]; %#ok<AGROW>
                tr('Leaving %s\n', f.name);
            end
            continue;
        end

        if isempty(regexp(f.name, '\.m', 'ONCE')) % not .m file
            continue;
        end

        filename = [directory f.name];
        tr('\t%s ... ', filename);
        if ischar(new)
            bakfilename = regexprep(filename, '\.m', '.m_');
            movefile(filename, bakfilename, 'f');
            fr = fopen(bakfilename, 'r');
            fw = fopen(filename, 'w');
        else
            fr = fopen(filename, 'r');
            fw = -1;
        end
        line = fgets(fr);
        while ischar(line)
            [~,~,~,id] = regexp(line, pattern);
            allids = [allids id]; %#ok<AGROW>
            if fw > 0
                for item = id
                    [tf,loc] = ismember(item{:}, old);
                    if tf
                        line = regexprep(line, old{loc}, new{loc});
                    end
                end
                fwrite(fw, line);
            end
            line = fgets(fr);   
        end
        fclose(fr);
        if fw > 0, fclose(fw); end
        tr('done\n');
    end
end

function nothing(varargin)
end
